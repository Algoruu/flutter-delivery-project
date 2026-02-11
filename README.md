# 🛵 방문자 전용 지도 (Delivery Map)

> **"여기는 오토바이 진입 금지입니다."** ⛔  
> 더 이상 아파트 단지 입구에서 당황하지 마세요. 방문자분들을 위한 실시간 진입로 정보 공유 플랫폼입니다.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Naver Map](https://img.shields.io/badge/Naver_Map_API-03C75A?style=for-the-badge&logo=naver&logoColor=white)

---

## 📱 프로젝트 소개 (Introduction)

배달 업무를 하다 보면 복잡한 아파트 단지나 오피스텔에서 "**방문자 전용 출입구**"를 찾지 못해 시간을 허비하는 경우가 많습니다.
이 앱은 **집단지성**(**Crowdsourcing**)을 활용하여 방문자가 직접 진입 가능한 경로와 불가능한 경로를 지도에 표시하고 공유하는 서비스입니다.

### 🌟 핵심 가치
* **시간 절약:** 헤매는 시간 최소화
* **정보 공유:** 내가 아는 길을 동료들에게 공유
* **안전 운행:** 무리한 진입 시도 방지

---

## 🚀 핵심 기능 (Key Features)

### 1. 📍 내 위치 기반 지도 (Live Map)
* **네이버 지도 API**를 활용하여 현재 위치 주변의 지도를 빠르고 정확하게 띄웁니다.
* GPS를 연동하여 이동 중에도 실시간으로 내 위치를 트래킹합니다.

### 2. 🎨 직관적인 마커 시스템 (Color-coded Markers)
지도 위에 핀을 꽂아 진입 가능 여부를 한눈에 파악할 수 있습니다.
* 🔴 **Red Marker:** 입주민 전용 / 오토바이 진입 금지 (도보 배달만 가능)
* 🟢 **Green Marker:** 방문자 전용 / 오토바이 진입 가능 / 지하주차장 연결

### 3. 🔍 장소 검색 & 핀 조정 기능 (Search & Pin Adjustment)
* **네이버 검색 API**(지역 검색)와 **Geocoding API**를 조합하여 장소명·도로명 주소 모두 검색 가능합니다.
* 검색 결과를 선택하면 해당 위치로 카메라가 이동하고, **핀 조정 모드**에 진입합니다.
* 지도를 드래그하여 **정확한 위치를 미세 조정**한 뒤 제보할 수 있습니다.
* 웹 버전에서도 동일한 검색·핀 조정 기능을 지원합니다.

### 4. 📢 실시간 제보 기능 (Report & Share)
* **Firebase Firestore**를 연동하여 데이터가 실시간으로 저장되고 모든 사용자에게 공유됩니다.
* 지도를 **터치**(**Long Press**)하여 누구나 쉽게 새로운 정보를 등록할 수 있습니다.
    * *"여기는 정문인데 오토바이 막아요!"*
    * *"후문 쪽 쪽문으로 들어가면 빠릅니다."*

---

## 📸 스크린샷 (Screenshots)

| 지도 메인 화면 | 마커 상세 정보(방문자 정보) | 마커 상세 정보(입주민 정보) |제보하기 화면 | 제보등록 화면 |
|:---:|:---:|:---:|:---:|:---:|
| ![메인화면](https://github.com/user-attachments/assets/db1a0ee6-a19a-4420-89d0-74c09c123b51) | ![마커 상세 정보 (방문자 정보)](https://github.com/user-attachments/assets/09d15478-e465-4f29-bad6-6a44a937a912) | ![마커 상세 정보(입주민 정보)](https://github.com/user-attachments/assets/e5a5043d-185f-42a2-9d67-9622e6879d52) |![제보하기](https://github.com/user-attachments/assets/dc0041a2-0b31-47d2-bce2-532f72698972) |![제보등록](https://github.com/user-attachments/assets/b02d5e78-ea9c-4515-8864-8525ebe813df) |


---

## 🛠 기술 스택 (Tech Stack)

* **Framework:** Flutter (3.38.9)
* **Language:** Dart
* **Backend & DB:** Firebase (Firestore Database)
* **Map API:** Naver Maps SDK for Flutter (`flutter_naver_map`, `flutter_naver_map_web`)
* **Search API:** Naver Search Local API (`openapi.naver.com`), Naver Cloud Geocoding API

---

## 🏁 시작하기 (Getting Started)

이 프로젝트를 로컬에서 실행하려면 다음 단계가 필요합니다.

### 1. 프로젝트 클론
```bash
git clone [https://github.com/Algoruu/delivery-map.git](https://github.com/Algoruu/delivery-map.git)
cd delivery-map
```
### 2. 패키지 설치
프로젝트 실행에 필요한 라이브러리들을 설치합니다.
```bash
flutter pub get
```
### 3. 환경 변수 설정 (.env)
보안을 위해 API Key는 코드에 직접 올리지 않고 관리합니다.<BR> 프로젝트 **최상위 경로**(**Root**)에 .env 파일을 생성하고, 네이버 클라우드 플랫폼에서 발급받은 Client ID를 입력하세요.(Dynamic Map, Geocoding을 선택합니다.)<BR>

https://developers.naver.com/apps/#/register?defaultScope=search
여기서 도로명 주소가 아닌, 키워드 검색 기능을 위해 따로 또 Client ID를 발급받아야합니다.

*(주의: `.env` 파일은 `.gitignore`에 포함되어 있어 깃허브에는 올라가지 않습니다.)*

[.env 파일 예시]
```
CLIENT_ID=여기에_당신의_클라이언트_ID_입력
CLIENT_SECRET=여기에_당신의_클라이언트_SECRET_입력
NAVER_SEARCH_CLIENT_ID=여기에_당신의_검색_클라이언트_ID_입력
NAVER_SEARCH_CLIENT_SECRET=여기에_당신의_검색_클라이언트_SECRET_입력
```

## 📅 추후 업데이트 계획 (Roadmap)
현재 핵심 기능 3가지가 구현되어 있으며, 추후 다음 기능들이 업데이트될 예정입니다.

* [x] 🗺️ 지도 표시 및 내 위치 트래킹 (Naver Map API)

* [x] 📍 진입 가능/불가능 마커 표시 (Custom Markers)

* [x] 📢 Firebase 연동 실시간 제보 시스템 (Firestore)

* [x] 🔍 장소명/주소 검색 기능 (Naver Search & Geocoding API)

* [x] 📌 핀 위치 미세 조정 모드 (Pin Adjustment Mode)

* [x] 🌐 웹 버전 지원 (Flutter Web + CORS Proxy)

* [ ] 🔐 회원가입 및 로그인 (Firebase Auth) - Next Update!

* [ ] 🛵 마커 필터링 (오토바이/도보/자전거)

* [ ] 🏆 베스트 제보자 랭킹 시스템