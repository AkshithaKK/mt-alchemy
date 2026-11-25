MT ALCHEMY — PHOTO-ONLY DOWNLOAD PATCH

This package contains NO Dart files, NO Firebase files, and NO pubspec.yaml.
It does not overwrite or modify your working website code.

WHAT IT DOES
- Downloads the exact photo URLs referenced by the visual-refresh folder's
  lib/widgets/ui.dart into your project's assets/images/ directory.
- Gives each PhotoUrls entry its own local JPG filename.
- Leaves all existing project files untouched.

HOW TO USE
1. Extract this ZIP into the ROOT of your actual Flutter project — the same
   folder that contains pubspec.yaml, lib/, and assets/.
2. If Windows asks whether to merge the assets folder, choose Merge. Do not
   overwrite any existing files. This ZIP contains only the download script
   and this guide; it does not replace your existing assets.
3. In Android Studio, open Terminal at the project root and run:

   powershell -ExecutionPolicy Bypass -File .\download_mt_alchemy_photos.ps1

4. Wait until it says all photo files downloaded successfully.
5. Check assets/images/ for the generated JPG files.

IMPORTANT LIMITATION
Your current ui.dart uses Image.network with online URLs. Downloading these
files alone does not make Flutter automatically use the local JPGs. To display
these local copies, the photo references in ui.dart must later be changed to
Image.asset paths. That is a small image-only display change; it does not
require changing Firebase, authentication, Firestore, app navigation, or other
business logic. This package intentionally does not modify ui.dart.

PHOTO LIST
- hero -> assets/images/hero.jpg
- learning -> assets/images/learning.jpg
- resources -> assets/images/resources.jpg
- training -> assets/images/training.jpg
- teamwork -> assets/images/teamwork.jpg
- aboutStory -> assets/images/aboutstory.jpg
- servicesHero -> assets/images/serviceshero.jpg
- upskillingHero -> assets/images/upskillinghero.jpg
- storeHero -> assets/images/storehero.jpg
- contactHero -> assets/images/contacthero.jpg
- aboutInnovation -> assets/images/aboutinnovation.jpg
- aboutCollaboration -> assets/images/aboutcollaboration.jpg
- aboutGrowth -> assets/images/aboutgrowth.jpg
- serviceProgrammes -> assets/images/serviceprogrammes.jpg
- serviceCorporate -> assets/images/servicecorporate.jpg
- serviceProgress -> assets/images/serviceprogress.jpg
- serviceResources -> assets/images/serviceresources.jpg
- courseTeams -> assets/images/courseteams.jpg
- courseEmotional -> assets/images/courseemotional.jpg
- courseWellbeing -> assets/images/coursewellbeing.jpg
- courseLeadership -> assets/images/courseleadership.jpg
- productClarity -> assets/images/productclarity.jpg
- productLeadership -> assets/images/productleadership.jpg
- productJournal -> assets/images/productjournal.jpg
- productWorkbook -> assets/images/productworkbook.jpg
- productCards -> assets/images/productcards.jpg
- productKit -> assets/images/productkit.jpg
- books -> assets/images/books.jpg
- learningOffice -> assets/images/learningoffice.jpg

The source URLs are retained in the PowerShell script. Internet access is required during download.
