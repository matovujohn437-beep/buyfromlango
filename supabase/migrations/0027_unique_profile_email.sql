BEGIN;

WITH ranked_users AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY lower(btrim(email))
      ORDER BY created_at ASC, id ASC
    ) AS duplicate_rank
  FROM auth.users
  WHERE NULLIF(btrim(email), '') IS NOT NULL
)
DELETE FROM auth.users AS duplicate
USING ranked_users
WHERE duplicate.id = ranked_users.id
  AND ranked_users.duplicate_rank > 1;

ALTER TABLE public.profiles
  ADD COLUMN email text;

UPDATE public.profiles AS profile
SET email = NULLIF(auth_user.email, '')
FROM auth.users AS auth_user
WHERE auth_user.id = profile.id;

CREATE UNIQUE INDEX profiles_email_unique_idx
  ON public.profiles (lower(btrim(email)))
  WHERE NULLIF(btrim(email), '') IS NOT NULL;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, email)
  VALUES (
    NEW.id,
    NULLIF(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(
      NULLIF(NEW.phone, ''),
      NULLIF(NEW.raw_user_meta_data ->> 'phone', '')
    ),
    NULLIF(NEW.email, '')
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_profile_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  auth_email text;
BEGIN
  SELECT NULLIF(auth_user.email, '')
  INTO auth_email
  FROM auth.users AS auth_user
  WHERE auth_user.id = NEW.id;

  IF NOT FOUND OR NEW.email IS DISTINCT FROM auth_email THEN
    RAISE EXCEPTION 'Profile email must match the authenticated email address'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_protect_email
  BEFORE INSERT OR UPDATE OF email ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profile_email();

CREATE OR REPLACE FUNCTION public.sync_profile_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.profiles
  SET email = NULLIF(NEW.email, '')
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER auth_user_sync_profile_email
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  WHEN (OLD.email IS DISTINCT FROM NEW.email)
  EXECUTE FUNCTION public.sync_profile_email();

COMMIT;
