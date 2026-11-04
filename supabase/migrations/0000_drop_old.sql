DO $$
DECLARE
  object_record record;
BEGIN
  FOR object_record IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      object_record.policyname,
      object_record.schemaname,
      object_record.tablename
    );
  END LOOP;
END;
$$;

DROP VIEW IF EXISTS public.public_profiles CASCADE;

DO $$
DECLARE
  table_record record;
BEGIN
  FOR table_record IN
    SELECT class.relname AS tablename, class.relkind
    FROM pg_class AS class
    JOIN pg_namespace AS namespace ON namespace.oid = class.relnamespace
    WHERE namespace.nspname = 'public'
      AND class.relkind IN ('r', 'p', 'f')
  LOOP
    IF table_record.relkind = 'f' THEN
      EXECUTE format('DROP FOREIGN TABLE IF EXISTS public.%I CASCADE', table_record.tablename);
    ELSE
      EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', table_record.tablename);
    END IF;
  END LOOP;
END;
$$;
