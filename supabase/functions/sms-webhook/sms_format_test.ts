import { fitOneSms, oneLine, smsUnits, usesGsm7 } from "./sms_format.ts";

Deno.test("fits GSM-7 replies into one SMS and preserves line breaks", () => {
  const reply = fitOneSms(
    Array.from({ length: 20 }, (_, index) => `${index + 1}. Item ${index + 1}`)
      .join("\n"),
  );

  if (!usesGsm7(reply) || smsUnits(reply, true) > 160) {
    throw new Error("GSM-7 reply exceeds one SMS segment.");
  }
  if (!reply.includes("\n") || reply.includes("Item 1Item 2")) {
    throw new Error("Listing entries must remain on separate lines.");
  }
});

Deno.test("counts GSM extension characters as two septets", () => {
  const reply = fitOneSms("^".repeat(100));

  if (smsUnits(reply, true) > 160) {
    throw new Error("GSM extension characters exceed one SMS segment.");
  }
});

Deno.test("fits Unicode replies into one SMS", () => {
  const reply = fitOneSms("🙂".repeat(80));

  if (usesGsm7(reply) || smsUnits(reply, false) > 70) {
    throw new Error("Unicode reply exceeds one SMS segment.");
  }
});

Deno.test("listing titles cannot inject additional rows", () => {
  if (oneLine("Beans\r\nMaize") !== "Beans Maize") {
    throw new Error("Listing title was not normalized to one line.");
  }
});