import fs from 'fs';
import path from 'path';

export interface RawRate {
  institutionName: string;
  rateType: 'SAC' | 'Price';
  rateValue: number;
  maxLTV: number;
  minTerm: number;
  maxTerm: number;
  maxAge: number;
}

export function parseRatesCSV(filePath: string): RawRate[] {
  if (!fs.existsSync(filePath)) {
    throw new Error(`CSV file not found at: ${filePath}`);
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split(/\r?\n/);
  const results: RawRate[] = [];

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const columns = line.split(',');
    if (columns.length < 7) {
      continue;
    }

    const [
      institutionName,
      rateType,
      rateValueStr,
      maxLTVStr,
      minTermStr,
      maxTermStr,
      maxAgeStr,
    ] = columns;

    results.push({
      institutionName: institutionName.trim(),
      rateType: rateType.trim() as 'SAC' | 'Price',
      rateValue: parseFloat(rateValueStr),
      maxLTV: parseFloat(maxLTVStr),
      minTerm: parseInt(minTermStr, 10),
      maxTerm: parseInt(maxTermStr, 10),
      maxAge: parseInt(maxAgeStr, 10),
    });
  }

  return results;
}
