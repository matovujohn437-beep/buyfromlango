UPDATE public.profiles
SET phone = NULL
WHERE btrim(phone) = '';

CREATE UNIQUE INDEX IF NOT EXISTS profiles_phone_unique_idx
  ON public.profiles (phone);

CREATE OR REPLACE FUNCTION public.is_profile_phone_available(p_phone text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p_phone !~ '^\+256[0-9]{9}$' THEN false
    ELSE NOT EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE phone = p_phone
    )
  END;
$$;

REVOKE ALL ON FUNCTION public.is_profile_phone_available(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_profile_phone_available(text)
  TO anon, authenticated;
