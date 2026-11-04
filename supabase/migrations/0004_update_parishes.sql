BEGIN;

CREATE TEMP TABLE requested_parishes (
  district_name text NOT NULL,
  subcounty_name text NOT NULL,
  parish_name text NOT NULL,
  PRIMARY KEY (district_name, subcounty_name, parish_name)
) ON COMMIT DROP;

INSERT INTO requested_parishes (district_name, subcounty_name, parish_name)
VALUES
  ('Lira', 'Agweng', 'Abala'),
  ('Lira', 'Agweng', 'Acelela'),
  ('Lira', 'Agweng', 'Angolocom'),
  ('Lira', 'Agweng', 'Baroganda'),
  ('Lira', 'Agweng', 'Dim'),
  ('Lira', 'Agweng', 'Orit'),
  ('Lira', 'Agweng', 'Te Adwong'),
  ('Lira', 'Agweng', 'Te-Ob Uru'),
  ('Lira', 'Agweng Town Council', 'Acelela Ward'),
  ('Lira', 'Agweng Town Council', 'Agweng Ward'),
  ('Lira', 'Agweng Town Council', 'Amiabil Ward'),
  ('Lira', 'Agweng Town Council', 'Wiakot Ward'),
  ('Lira', 'Agweng Town Council', 'Widam Ward'),
  ('Lira', 'Aromo', 'Apua'),
  ('Lira', 'Aromo', 'Bar-Pii'),
  ('Lira', 'Aromo', 'Odoca'),
  ('Lira', 'Aromo', 'Odoro'),
  ('Lira', 'Aromo', 'Otara'),
  ('Lira', 'Ayami', 'Acutikumu'),
  ('Lira', 'Ayami', 'Apuce'),
  ('Dokolo', 'Dokolo', 'Abenyo'),
  ('Dokolo', 'Dokolo', 'Acanpii'),
  ('Dokolo', 'Dokolo', 'Adagmon'),
  ('Dokolo', 'Dokolo', 'Alenga'),
  ('Dokolo', 'Dokolo', 'Anangogwec'),
  ('Dokolo', 'Dokolo', 'Awiri'),
  ('Dokolo', 'Okwalongwen', 'Abalang'),
  ('Dokolo', 'Okwalongwen', 'Adagnyeko'),
  ('Dokolo', 'Okwalongwen', 'Akwanga'),
  ('Dokolo', 'Okwalongwen', 'Aluti'),
  ('Dokolo', 'Okwalongwen', 'Okwalongwen'),
  ('Dokolo', 'Adeknino', 'Adeknino'),
  ('Dokolo', 'Adeknino', 'Adwong-Owor'),
  ('Dokolo', 'Adeknino', 'Ajiba'),
  ('Dokolo', 'Adeknino', 'Aridi'),
  ('Dokolo', 'Adeknino', 'Awelo'),
  ('Dokolo', 'Kangai', 'Adwila'),
  ('Dokolo', 'Kangai', 'Angwenya'),
  ('Dokolo', 'Kangai', 'Ayuni'),
  ('Dokolo', 'Kangai', 'Chwagere'),
  ('Dokolo', 'Kangai Town Council', 'Akurolango Ward'),
  ('Dokolo', 'Kangai Town Council', 'Angai Ward'),
  ('Dokolo', 'Kangai Town Council', 'Angwenya Ward'),
  ('Dokolo', 'Kangai Town Council', 'Ayuni Ward'),
  ('Dokolo', 'Dokolo Town Council', 'Central Ward'),
  ('Dokolo', 'Dokolo Town Council', 'Eastern Ward'),
  ('Dokolo', 'Dokolo Town Council', 'Northern Ward'),
  ('Dokolo', 'Dokolo Town Council', 'Southern Ward'),
  ('Dokolo', 'Dokolo Town Council', 'Western Ward'),
  ('Oyam', 'Otwal', 'Acokara'),
  ('Oyam', 'Otwal', 'Ader'),
  ('Oyam', 'Otwal', 'Amukugungu'),
  ('Oyam', 'Otwal', 'Anyomolyec'),
  ('Oyam', 'Otwal', 'Okii'),
  ('Oyam', 'Otwal', 'Wanglobo'),
  ('Oyam', 'Oyam Town Council', 'Adyegi'),
  ('Oyam', 'Oyam Town Council', 'Akaka'),
  ('Oyam', 'Oyam Town Council', 'Atura'),
  ('Oyam', 'Oyam Town Council', 'Wirao'),
  ('Oyam', 'Kamdini', 'Juma'),
  ('Oyam', 'Kamdini', 'Ocini'),
  ('Oyam', 'Kamdini', 'Pukica'),
  ('Oyam', 'Kamdini', 'Zambia'),
  ('Oyam', 'Aber', 'Adigo'),
  ('Oyam', 'Aber', 'Agulurude'),
  ('Oyam', 'Aber', 'Alidi'),
  ('Oyam', 'Aber', 'Alutkot'),
  ('Amolatar', 'Awello', 'Akongomit'),
  ('Amolatar', 'Awello', 'Anamwany'),
  ('Amolatar', 'Awello', 'Atero'),
  ('Amolatar', 'Awello', 'Atomoro'),
  ('Amolatar', 'Awello', 'Odyedo'),
  ('Amolatar', 'Etam', 'Abwockwar'),
  ('Amolatar', 'Etam', 'Anamido'),
  ('Amolatar', 'Etam', 'Awiodyek'),
  ('Amolatar', 'Opali', 'Acan Oryema'),
  ('Amolatar', 'Opali', 'Adonyimo'),
  ('Amolatar', 'Opali', 'Agweng'),
  ('Amolatar', 'Opali', 'Akuriluba'),
  ('Amolatar', 'Opali', 'Opali'),
  ('Amolatar', 'Opali', 'Otira'),
  ('Amolatar', 'Amolatar', 'Kongoro'),
  ('Amolatar', 'Amolatar', 'Muchora'),
  ('Amolatar', 'Amolatar', 'Otike'),
  ('Amolatar', 'Amolatar', 'Alemere'),
  ('Kole', 'Bala', 'Amoilela'),
  ('Kole', 'Bala', 'Angic'),
  ('Kole', 'Bala', 'Aumi'),
  ('Kole', 'Bala', 'Bala'),
  ('Kole', 'Bala', 'Omoladyang'),
  ('Kole', 'Bala', 'Omuge'),
  ('Kole', 'Bala', 'Omwara'),
  ('Kole', 'Lwala', 'Okwor'),
  ('Kole', 'Lwala', 'Telela'),
  ('Kole', 'Akalo', 'Bar-Akalo'),
  ('Kole', 'Akalo', 'Eastern Ward A'),
  ('Otuke', 'Adwari', 'Adverakonya'),
  ('Otuke', 'Adwari', 'Okee'),
  ('Otuke', 'Adwari', 'Okere'),
  ('Otuke', 'Adwari', 'Olarokvon'),
  ('Otuke', 'Adwari Town Council', 'Akwera Ward'),
  ('Otuke', 'Adwari Town Council', 'Aliwang Ward');

DELETE FROM public.parishes;

INSERT INTO public.subcounties (district_id, name)
SELECT DISTINCT districts.id, requested_parishes.subcounty_name
FROM requested_parishes
JOIN public.districts
  ON districts.name = requested_parishes.district_name
ON CONFLICT (district_id, name) DO NOTHING;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM (
      SELECT DISTINCT district_name
      FROM requested_parishes
    ) AS requested_districts
    LEFT JOIN public.districts
      ON districts.name = requested_districts.district_name
    WHERE districts.id IS NULL
  ) THEN
    RAISE EXCEPTION 'A district referenced by requested parish data is missing';
  END IF;
END;
$$;

INSERT INTO public.parishes (subcounty_id, name)
SELECT subcounties.id, requested_parishes.parish_name
FROM requested_parishes
JOIN public.districts
  ON districts.name = requested_parishes.district_name
JOIN public.subcounties
  ON subcounties.district_id = districts.id
 AND subcounties.name = requested_parishes.subcounty_name;

INSERT INTO public.parishes (subcounty_id, name)
SELECT subcounties.id, subcounties.name || suffix.parish_suffix
FROM public.subcounties
CROSS JOIN (VALUES (' A'), (' B')) AS suffix(parish_suffix)
WHERE NOT EXISTS (
  SELECT 1
  FROM requested_parishes
  JOIN public.districts
    ON districts.name = requested_parishes.district_name
  WHERE districts.id = subcounties.district_id
    AND requested_parishes.subcounty_name = subcounties.name
);

COMMIT;
