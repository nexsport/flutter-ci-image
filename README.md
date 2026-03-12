# Flutter CI Docker Image

Image Docker pour les pipelines CI/CD Flutter Android de NexSport.

Basee sur [gmeligio/flutter-docker-image](https://github.com/gmeligio/flutter-docker-image), avec l'ajout de **Node.js** (requis par Forgejo Actions).

## Contenu

- Flutter SDK (version configurable)
- Java 21 (OpenJDK headless, natif Trixie)
- Android SDK : cmdline-tools, platform-tools, build-tools, NDK, CMake
- Node.js 22 LTS
- Ruby + Fastlane (gem cachee)
- Git, curl, unzip
- Licences Android acceptees
- Gradle pre-telecharge

## Utilisation

### Dans un workflow Forgejo

```yaml
jobs:
  build:
    runs-on: ubuntu
    container:
      image: nxsonpvmsgit001.nexsport.priv:3000/infrastructure/docker-flutter-ci:3.41.4
    steps:
      - uses: actions/checkout@v4
      - run: flutter pub get
      - run: flutter build appbundle --release
```

### Build local

```bash
docker build \
  --target android \
  --build-arg flutter_version=3.41.4 \
  --build-arg fastlane_version=2.232.1 \
  --build-arg android_build_tools_version=35.0.0 \
  --build-arg android_platform_versions="36" \
  --build-arg android_ndk_version=28.2.13676358 \
  --build-arg cmake_version=3.22.1 \
  -t flutter-ci:3.41.4 \
  .
```

## Mise a jour Flutter

1. Mettre a jour la version dans `.env.example`
2. Creer un tag git correspondant (ex: `3.42.0`)
3. Le workflow `.forgejo/workflows/build.yml` build et push automatiquement

## Versions des outils

Voir `.env.example` pour les versions actuelles.
