#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const metadataPath = path.join(root, "docs", "app-store", "metadata.json");
const metadata = JSON.parse(await readFile(metadataPath, "utf8"));
const errors = [];

const requiredLocales = ["en-US", "de-DE", "uk"];
const unsupportedClaims = [
  /a[- ]?to[- ]?b/i,
  /journey planning/i,
  /route planning/i,
  /cross-device/i,
  /cloud sync/i,
  /password recovery/i,
  /ticket purchase/i
];

function countCharacters(value) {
  return [...value].length;
}

function requireString(locale, field, maximum, minimum = 1) {
  const value = metadata.localizations?.[locale]?.[field];
  if (typeof value !== "string") {
    errors.push(`${locale}.${field} must be a string`);
    return "";
  }

  const length = countCharacters(value);
  if (length < minimum || length > maximum) {
    errors.push(`${locale}.${field} has ${length} characters; expected ${minimum}-${maximum}`);
  }
  return value;
}

function validateOptionalHttps(field) {
  const value = metadata.app?.[field];
  if (value === null) return;
  if (typeof value !== "string" || !/^https:\/\/[^\s]+$/i.test(value)) {
    errors.push(`${field} must be null while pending or a public HTTPS URL`);
  }
}

if (metadata.schemaVersion !== 1) errors.push("schemaVersion must be 1");
if (metadata.app?.bundleId !== "wellbe.TrafficVienna") errors.push("bundleId must match the Xcode project");
validateOptionalHttps("privacyPolicyUrl");
validateOptionalHttps("supportUrl");

for (const locale of requiredLocales) {
  if (!metadata.localizations?.[locale]) {
    errors.push(`missing localization: ${locale}`);
    continue;
  }

  const name = requireString(locale, "name", 30, 2);
  const subtitle = requireString(locale, "subtitle", 30);
  const promotionalText = requireString(locale, "promotionalText", 170);
  const description = requireString(locale, "description", 4000);
  const keywords = requireString(locale, "keywords", 100);
  const keywordBytes = Buffer.byteLength(keywords, "utf8");

  if (keywordBytes > 100) errors.push(`${locale}.keywords uses ${keywordBytes} UTF-8 bytes; maximum is 100`);
  for (const keyword of keywords.split(",")) {
    if (countCharacters(keyword.trim()) <= 2) errors.push(`${locale}.keywords contains a keyword shorter than three characters: ${keyword}`);
  }

  const marketingCopy = [name, subtitle, promotionalText, description].join("\n");
  for (const claim of unsupportedClaims) {
    if (claim.test(marketingCopy)) errors.push(`${locale} contains unsupported marketing claim: ${claim}`);
  }
}

const unexpectedLocales = Object.keys(metadata.localizations ?? {}).filter(locale => !requiredLocales.includes(locale));
if (unexpectedLocales.length) errors.push(`unvalidated localizations: ${unexpectedLocales.join(", ")}`);

if (errors.length) {
  console.error(errors.map(error => `[app-store-metadata] ${error}`).join("\n"));
  process.exit(1);
}

const pendingUrls = ["privacyPolicyUrl", "supportUrl"].filter(field => metadata.app[field] === null);
console.log(`[app-store-metadata] OK${pendingUrls.length ? ` (release URLs pending: ${pendingUrls.join(", ")})` : ""}`);
