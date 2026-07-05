import path from 'path';
import { prisma } from './db.ts';
import { RateCrawlerService } from './crawler.service.ts';

async function main() {
  console.log('Starting Rate Crawler synchronization...');
  
  const csvPath = path.resolve(process.cwd(), 'resources', 'rates.csv');
  console.log(`Reading CSV from: ${csvPath}`);

  const crawlerService = new RateCrawlerService();

  try {
    await crawlerService.importRatesFromCSV(csvPath);
    console.log('Rate Crawler synchronization completed successfully!');
  } catch (error) {
    console.error('Error during synchronization:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
