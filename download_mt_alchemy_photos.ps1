$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$imageDir = Join-Path $projectRoot 'assets\images'
New-Item -ItemType Directory -Force -Path $imageDir | Out-Null
$photos = @(
    @{ Name = 'hero'; File = 'hero.jpg'; Url = 'https://images.unsplash.com/photo-1603195827187-459ab02554a0?auto=format&fit=crop&w=1600&q=85' },
    @{ Name = 'learning'; File = 'learning.jpg'; Url = 'https://images.unsplash.com/photo-1759984782211-3a02ca78e6ac?auto=format&fit=crop&w=1200&q=85' },
    @{ Name = 'resources'; File = 'resources.jpg'; Url = 'https://images.unsplash.com/photo-1743385779312-73ea241025d8?auto=format&fit=crop&w=1200&q=85' },
    @{ Name = 'training'; File = 'training.jpg'; Url = 'https://images.pexels.com/photos/8424454/pexels-photo-8424454.jpeg?auto=compress&cs=tinysrgb&w=1400' },
    @{ Name = 'teamwork'; File = 'teamwork.jpg'; Url = 'https://images.unsplash.com/photo-1759310610480-48649b55fbdf?auto=format&fit=crop&w=1400&q=85' },
    @{ Name = 'aboutStory'; File = 'aboutstory.jpg'; Url = 'https://images.pexels.com/photos/34774312/pexels-photo-34774312.jpeg?auto=compress&cs=tinysrgb&w=1600' },
    @{ Name = 'servicesHero'; File = 'serviceshero.jpg'; Url = 'https://images.pexels.com/photos/33714896/pexels-photo-33714896.jpeg?auto=compress&cs=tinysrgb&w=1600' },
    @{ Name = 'upskillingHero'; File = 'upskillinghero.jpg'; Url = 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1600&q=85' },
    @{ Name = 'storeHero'; File = 'storehero.jpg'; Url = 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1600&q=85' },
    @{ Name = 'contactHero'; File = 'contacthero.jpg'; Url = 'https://images.pexels.com/photos/7648234/pexels-photo-7648234.jpeg?auto=compress&cs=tinysrgb&w=1600' },
    @{ Name = 'aboutInnovation'; File = 'aboutinnovation.jpg'; Url = 'https://images.pexels.com/photos/6773652/pexels-photo-6773652.jpeg?auto=compress&cs=tinysrgb&w=1000' },
    @{ Name = 'aboutCollaboration'; File = 'aboutcollaboration.jpg'; Url = 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'aboutGrowth'; File = 'aboutgrowth.jpg'; Url = 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'serviceProgrammes'; File = 'serviceprogrammes.jpg'; Url = 'https://images.pexels.com/photos/8761525/pexels-photo-8761525.jpeg?auto=compress&cs=tinysrgb&w=1000' },
    @{ Name = 'serviceCorporate'; File = 'servicecorporate.jpg'; Url = 'https://images.pexels.com/photos/34046709/pexels-photo-34046709.jpeg?auto=compress&cs=tinysrgb&w=1000' },
    @{ Name = 'serviceProgress'; File = 'serviceprogress.jpg'; Url = 'https://images.pexels.com/photos/7647957/pexels-photo-7647957.jpeg?auto=compress&cs=tinysrgb&w=1000' },
    @{ Name = 'serviceResources'; File = 'serviceresources.jpg'; Url = 'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'courseTeams'; File = 'courseteams.jpg'; Url = 'https://images.pexels.com/photos/15141493/pexels-photo-15141493.jpeg?auto=compress&cs=tinysrgb&w=1000' },
    @{ Name = 'courseEmotional'; File = 'courseemotional.jpg'; Url = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'courseWellbeing'; File = 'coursewellbeing.jpg'; Url = 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'courseLeadership'; File = 'courseleadership.jpg'; Url = 'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'productClarity'; File = 'productclarity.jpg'; Url = 'https://images.unsplash.com/photo-1455390582262-044c40f0e7b6?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'productLeadership'; File = 'productleadership.jpg'; Url = 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'productJournal'; File = 'productjournal.jpg'; Url = 'https://images.unsplash.com/photo-1517842645767-c639042777db?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'productWorkbook'; File = 'productworkbook.jpg'; Url = 'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'productCards'; File = 'productcards.jpg'; Url = 'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'productKit'; File = 'productkit.jpg'; Url = 'https://images.unsplash.com/photo-1543269865-cbf427effbad?auto=format&fit=crop&w=1000&q=85' },
    @{ Name = 'books'; File = 'books.jpg'; Url = 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=1200&q=85' },
    @{ Name = 'learningOffice'; File = 'learningoffice.jpg'; Url = 'https://images.unsplash.com/photo-1758876021859-bd2371d8f0a2?auto=format&fit=crop&w=1200&q=85' },
)
$failed = @()
foreach ($photo in $photos) {
    $destination = Join-Path $imageDir $photo.File
    try {
        Write-Host ('Downloading ' + $photo.Name + ' ...')
        Invoke-WebRequest -Uri $photo.Url -OutFile $destination -UseBasicParsing
        if ((Get-Item $destination).Length -lt 1000) { throw 'Downloaded file is unexpectedly small.' }
    } catch {
        $failed += ($photo.Name + ': ' + $_.Exception.Message)
        Write-Warning ($photo.Name + ' failed: ' + $_.Exception.Message)
    }
}
Write-Host ''
Write-Host ('Finished. Downloaded files are in: ' + $imageDir)
if ($failed.Count -gt 0) {
    Write-Warning 'Some downloads failed:'
    $failed | ForEach-Object { Write-Warning $_ }
    exit 1
}
Write-Host 'All photo files downloaded successfully.'
