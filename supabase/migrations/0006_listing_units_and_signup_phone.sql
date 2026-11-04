ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS unit text;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone)
  VALUES (
    NEW.id,
    NULLIF(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(
      NULLIF(NEW.phone, ''),
      NULLIF(NEW.raw_user_meta_data ->> 'phone', '')
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

UPDATE public.profiles AS profile
SET phone = COALESCE(
  NULLIF(auth_user.phone, ''),
  NULLIF(auth_user.raw_user_meta_data ->> 'phone', '')
)
FROM auth.users AS auth_user
WHERE auth_user.id = profile.id
  AND profile.phone IS NULL
  AND (
    NULLIF(auth_user.phone, '') IS NOT NULL
    OR NULLIF(auth_user.raw_user_meta_data ->> 'phone', '') IS NOT NULL
  );
