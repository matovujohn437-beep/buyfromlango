const gsmBasicCodes = new Set(
  Array.from(
    "@\u00A3$\u00A5\u00E8\u00E9\u00F9\u00EC\u00F2\u00C7\n\u00D8\u00F8\r\u00C5\u00E5\u0394_\u03A6\u0393\u039B\u03A9\u03A0\u03A8\u03A3\u0398\u039E\u00C6\u00E6\u00DF\u00C9 !\"#\u00A4%&'()*+,-./0123456789:;<=>?\u00A1ABCDEFGHIJKLMNOPQRSTUVWXYZ\u00C4\u00D6\u00D1\u00DC\u00A7\u00BFabcdefghijklmnopqrstuvwxyz\u00E4\u00F6\u00F1\u00FC\u00E0",
  ).map((character) => character.codePointAt(0)!),
);
const gsmExtensionCodes = new Set(
  Array.from("^{}\\[~]|\u20AC").map((character) =>
    character.codePointAt(0)!
  ),
);

export function usesGsm7(text: string): boolean {
  return [...text].every((character) => {
    const code = character.codePointAt(0)!;
    return gsmBasicCodes.has(code) || gsmExtensionCodes.has(code);
  });
}

export function smsUnits(text: string, isGsm7: boolean): number {
  return [...text].reduce((units, character) => {
    if (!isGsm7) return units + character.length;
    return units + (gsmExtensionCodes.has(character.codePointAt(0)!) ? 2 : 1);
  }, 0);
}

function truncateSmsLine(line: string, limit: number, isGsm7: boolean): string {
  const suffix = "...";
  const budget = limit - smsUnits(suffix, isGsm7);
  let result = "";
  let units = 0;
  for (const character of line) {
    const characterUnits = smsUnits(character, isGsm7);
    if (units + characterUnits > budget) break;
    result += character;
    units += characterUnits;
  }
  return result + suffix;
}

export function fitOneSms(text: string): string {
  const isGsm = usesGsm7(text);
  const limit = isGsm ? 160 : 70;
  if (smsUnits(text, isGsm) <= limit) return text;

  const keptLines: string[] = [];
  for (const line of text.split("\n")) {
    const candidate = [...keptLines, line].join("\n");
    if (smsUnits(candidate, isGsm) <= limit) {
      keptLines.push(line);
      continue;
    }
    if (keptLines.length === 0) {
      return truncateSmsLine(line, limit, isGsm);
    }
    const withEllipsis = [...keptLines, "..."].join("\n");
    return smsUnits(withEllipsis, isGsm) <= limit
      ? withEllipsis
      : keptLines.join("\n");
  }
  return keptLines.join("\n");
}

export function oneLine(value: unknown): string {
  return String(value ?? "").replace(/[\r\n]+/g, " ").trim();
}