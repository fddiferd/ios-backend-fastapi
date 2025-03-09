## Initial Project Setup

## Configure Locally
**AUTHENTICATE GCP**
```
gcloud auth login
gcloud auth application-default login
```
**ADD ENV VARS**
```
GCP_PROJECT_ID=""
REGION=""
GCP_BILLING_ACCOUNT=""
```

**BUILD THE PROJECT**
```
chmod +x scripts/initial_setup.sh
./scripts/initial_setup.sh
./scripts/initial_setup.sh
```



## Project Structure
```
wedge-cicd/
├── app/
│   ├── __init__.py
│   ├── main.py
│   └── api/
│       ├── __init__.py
│       └── v1/
│           ├── __init__.py
│           └── endpoints.py
├── tests/
│   └── test_api.py
├── pyproject.toml
├── poetry.lock
├── Dockerfile
├── .env
├── .gitignore
└── scripts/
    └── setup.sh
```

## iOS Project Setup

1. Install CocoaPods:
```bash
cd ios
pod install
```

2. Open the project:
```bash
open ios/WedgeGolf/WedgeGolf.xcodeproj
```

3. Set environment variables in Xcode:
- Add `BRANCH_NAME` and `PROJECT_NAME` to your scheme's environment variables