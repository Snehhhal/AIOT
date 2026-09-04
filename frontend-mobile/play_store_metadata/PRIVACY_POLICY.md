# Privacy Policy for PoleGuard

**Last Updated: September 2026**

This Privacy Policy explains how the **PoleGuard** mobile application ("we", "our", or "the App") collects, uses, and protects information when used by Citizens, Technicians, Engineers, Authorities, and Administrators.

## 1. Information We Collect

### A. Location Data (GPS Coordinates)
- **Citizens**: The App accesses coarse and fine location solely when the citizen submits an emergency pole hazard report or views nearby electrical poles on the safety map. Location data is only transmitted when an explicit action is initiated.
- **Field Personnel (Technicians / Engineers)**: Location is used to verify dispatch to the physical pole location and provide navigational routing to active work orders.

### B. Camera & Media
- **Hazard Evidence**: The App requests camera access when the user captures a photograph of a damaged utility pole, spark/arcing event, or flooded base. Images are uploaded to the municipal safety server for Computer Vision hazard analysis and triage verification.

### C. Authentication & Profile Information
- For utility personnel (Technicians, Engineers, Authorities, Administrators), the App collects name, email, department, role, and encrypted session credentials to enforce strict Role-Based Access Control (RBAC).

## 2. How We Use Collected Information
- To identify energized utility poles and prevent fatal electrocution accidents.
- To dispatch utility emergency response units and municipal disaster relief.
- To feed Computer Vision and Machine Learning algorithms for hazard classification.
- To maintain audit logs of grid maintenance, isolation procedures, and safety sign-offs.

## 3. Data Retention and Security
- All sensitive API traffic between the mobile client and backend servers is encrypted using Transport Layer Security (TLS 1.3 / HTTPS / WSS).
- Passwords are salted and hashed using PBKDF2 with SHA-256 before storage.
- Location and image data are stored in secured database volumes with strict role-based access restrictions.

## 4. Third-Party Sharing
- We do not sell, rent, or trade personal data with commercial third-party advertisers. Data is shared exclusively with municipal electrical utility providers and disaster management authorities for public safety and life preservation.

## 5. Contact
For questions regarding this privacy policy:
- **Repository**: https://github.com/Snehhhal/AIOT.git
- **Project**: PoleGuard Electrical Safety Capstone
