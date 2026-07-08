-- AlterTable
ALTER TABLE "institutions" ADD COLUMN     "validateAge" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "validateLTV" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "validateTerm" BOOLEAN NOT NULL DEFAULT true;
