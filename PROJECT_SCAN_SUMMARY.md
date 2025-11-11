# Project Scan Summary - PCEA Church Management System

## Overview
This is a comprehensive church management system for PCEA (Presbyterian Church of East Africa) with three main components:
1. **Backend API** - Laravel 9 PHP backend
2. **Admin Panel** - React + TypeScript web admin interface
3. **Mobile App** - Flutter mobile application

---

## Project Structure

```
project/
├── backend/          # Laravel 9 API Backend
├── adminpanel/       # React + TypeScript Admin Panel
└── pcea_church/      # Flutter Mobile App
```

---

## 1. Backend (Laravel 9)

### Technology Stack
- **Framework**: Laravel 9.19
- **PHP**: ^8.0.2
- **Authentication**: Laravel Sanctum
- **Database**: MySQL (via migrations)
- **Payment Integration**: M-Pesa (Safaricom)

### Key Features

#### Authentication & Authorization
- Multi-role authentication system
- Role-based access control (RBAC)
- Permission-based middleware
- Support for multiple user types:
  - Admins
  - Members
  - Leadership roles (Pastor, Elder, Deacon, Chairman, Secretary, Treasurer)
  - Ministry roles (Choir Leader, Youth Leader, Sunday School Teacher)

#### Core Models (13 Models)
1. **Member** - Church members with comprehensive profile data
2. **Contribution** - Financial contributions tracking
3. **Payment** - Payment transactions (M-Pesa integration)
4. **Role** - Role definitions with hierarchy
5. **Permission** - Permission system
6. **Dependency** - Member dependents/children
7. **Group** - Church groups/ministries
8. **Minute** - Meeting minutes
9. **Region** - Geographic regions
10. **Presbytery** - Church presbyteries
11. **Parish** - Church parishes
12. **County** - Counties
13. **Constituency** - Constituencies

#### API Routes Structure
- **213 route definitions** organized by role and functionality
- Public routes: Registration, login, password reset, QR verification
- Admin routes: User management, member management, roles/permissions
- Role-specific routes: Pastor, Elder, Deacon, Secretary, Treasurer, etc.
- Member routes: Profile, contributions, dependents, dashboard
- Payment routes: M-Pesa STK push and callbacks

#### Key Controllers
- **AuthController** - General authentication
- **MemberController** - Member management
- **ContributionsController** - Financial contributions
- **MpesaController** - Payment processing
- **QRController** - QR code generation/verification
- **MinutesController** - Meeting minutes
- **Role-specific controllers** for each leadership role

#### Services
- **MpesaService** - M-Pesa payment integration
- **PaymentSmsService** - SMS notifications for payments
- **SmsService** - General SMS service

#### Database Migrations (30+ migrations)
- User management tables
- Member profiles with images (profile & passport)
- Dependencies/dependents
- Contributions and payments
- Roles and permissions (RBAC)
- Geographic hierarchy (Regions > Presbyteries > Parishes)
- Groups and group memberships
- Chat system (conversations, messages)
- Pastoral files and notes
- Meeting minutes

#### Seeders
- **RolesAndPermissionsSeeder** - System roles and permissions
- **RegionsSeeder** - Geographic data
- **CountiesAndConstituenciesSeeder** - Location data
- **GroupsSeeder** - Church groups
- **ContributionSeeder** - Sample contribution data
- **AdminSeeder** - Default admin user

#### Events & Broadcasting
- Events configured for future use

#### Scheduled Tasks
- **SendBirthdayMessages** - Automated birthday notifications

---

## 2. Admin Panel (React + TypeScript)

### Technology Stack
- **Framework**: React 18.3
- **Language**: TypeScript 5.5
- **Build Tool**: Vite 5.4
- **Styling**: Tailwind CSS 3.4
- **UI Components**: Radix UI, Lucide React icons
- **State Management**: React Hooks
- **Routing**: React Router DOM 6.22
- **HTTP Client**: Axios 1.9
- **Charts**: Recharts 2.15
- **Real-time**: Socket.io Client 4.8
- **PDF Generation**: jsPDF 3.0, jsPDF-AutoTable
- **Excel**: XLSX 0.18
- **AI Integration**: Langchain 0.3 (Chatbot)

### Project Structure
```
adminpanel/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── DashboardLayout.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Footer.tsx
│   │   ├── ui/          # Reusable UI components
│   │   ├── chatbot.tsx
│   │   ├── navbar.tsx
│   │   ├── requireAuth.tsx
│   │   └── theme-provider.tsx
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   ├── members.tsx
│   │   ├── contributions.tsx
│   │   ├── congregation.tsx
│   │   ├── roles.tsx
│   │   ├── login.tsx
│   │   └── Welcome.tsx
│   ├── lib/
│   │   └── utils.ts
│   └── App.tsx
```

### Key Features
- **Dashboard** - Statistics, charts, quick actions
- **Member Management** - View, edit, manage members
- **Contributions** - Financial tracking and reporting
- **Congregations** - Manage church structure
- **Roles Management** - Role and permission administration
- **Authentication** - Protected routes with RequireAuth
- **Theme Support** - Dark/light mode with next-themes
- **Real-time Updates** - Socket.io integration
- **Data Export** - PDF and Excel export capabilities
- **AI Chatbot** - Langchain integration for assistance

---

## 3. Mobile App (Flutter)

### Technology Stack
- **Framework**: Flutter (Dart SDK ^3.9.0)
- **HTTP**: http 1.5
- **Local Storage**: shared_preferences 2.3
- **Image Handling**: image_picker 1.1, gal 2.3
- **PDF**: pdf 3.10, printing 5.11
- **QR Codes**: qr_flutter 4.1
- **Forms**: flutter_form_builder 9.2
- **Permissions**: permission_handler 11.3
- **File Picker**: file_picker 8.0
- **Animations**: lottie 3.1

### Project Structure
```
pcea_church/
├── lib/
│   ├── components/
│   │   ├── constant.dart
│   │   ├── settings.dart
│   │   ├── splash_screen.dart
│   │   └── welcome.dart
│   ├── config/
│   │   └── server.dart
│   ├── method/
│   │   └── api.dart
│   ├── screen/
│   │   ├── base_dashboard.dart
│   │   ├── dashboard_factory.dart
│   │   ├── login.dart
│   │   ├── member_dashboard.dart
│   │   ├── pastor_dashboard.dart
│   │   ├── elder_dashboard.dart
│   │   ├── deacon_dashboard.dart
│   │   ├── secretary_dashboard.dart
│   │   ├── treasurer_dashboard.dart
│   │   ├── choir_leader_dashboard.dart
│   │   ├── youth_leader_dashboard.dart
│   │   ├── sunday_school_teacher_dashboard.dart
│   │   ├── profile.dart
│   │   ├── payments.dart
│   │   ├── account_summary.dart
│   │   ├── minutes_list_page.dart
│   │   ├── minutes_page.dart
│   │   ├── view_minutes_page.dart
│   │   ├── digital_card.dart
│   │   ├── add_dependents.dart
│   │   ├── view_dependents.dart
│   │   └── [other screens]
│   ├── theme/
│   │   └── theme_controller.dart
│   └── main.dart
```

### Key Features
- **Role-Based Dashboards** - Different dashboards for each role
- **Member Management** - Profile, dependents, contributions
- **Digital ID Card** - QR code-based member identification
- **Payment Integration** - M-Pesa payments
- **Minutes Management** - View and manage meeting minutes
- **Dependents Management** - Add and manage family members
- **Account Summary** - Financial overview
- **Theme Support** - Adaptive theme with text scaling
- **Offline Support** - Shared preferences for local storage

### Supported Roles
- Pastor
- Elder
- Deacon
- Secretary
- Treasurer
- Choir Leader
- Youth Leader
- Sunday School Teacher
- Member (default)

---

## System Architecture

### Authentication Flow
1. Users authenticate via Laravel Sanctum
2. Tokens are issued and stored
3. Role-based access control enforced via middleware
4. Permissions checked at route and controller level

### Role Hierarchy
Roles have hierarchy levels (higher = more authority):
- Pastor (highest)
- Elder
- Deacon
- Chairman
- Secretary
- Treasurer
- Choir Leader
- Youth Leader
- Sunday School Teacher
- Member (lowest)

### Geographic Structure
```
Region
  └── Presbytery
      └── Parish
          └── Congregation
              └── Groups
```

### Data Flow
1. **Mobile App** ↔ **Backend API** (REST)
2. **Admin Panel** ↔ **Backend API** (REST)
3. **Payment Processing** ↔ **M-Pesa API** ↔ **Backend** (Webhooks)

---

## Key Integrations

### M-Pesa Payment Integration
- STK Push for mobile payments
- Callback handling for payment status
- Payment verification and tracking
- SMS notifications for payments

### SMS Service
- Payment confirmations
- Birthday notifications
- General notifications

### QR Code System
- Member identification via QR codes
- Public verification endpoint
- Digital membership cards

---

## Security Features

1. **Authentication**: Laravel Sanctum token-based auth
2. **Authorization**: Role and permission-based access control
3. **Middleware**: Multiple middleware layers for protection
4. **CSRF Protection**: Laravel CSRF token validation
5. **Password Reset**: Secure code-based password reset
6. **Image Upload**: Secure file handling for profile/passport images

---

## Database Schema Highlights

### Core Tables
- `members` - Main member profiles
- `users` - Authentication users
- `admins` - Admin users
- `contributions` - Financial contributions
- `payments` - Payment transactions
- `dependencies` - Member dependents
- `roles` - Role definitions
- `permissions` - Permission definitions
- `member_roles` - Member-role assignments (with scope)
- `role_permissions` - Role-permission mappings
- `minutes` - Meeting minutes
- `regions`, `presbyteries`, `parishes` - Geographic hierarchy
- `groups` - Church groups
- `group_member` - Group memberships

---

## Development Environment

### Backend Setup
- XAMPP (Windows)
- PHP 8.0+
- MySQL
- Composer for dependencies

### Admin Panel Setup
- Node.js
- npm/yarn
- Vite dev server

### Mobile App Setup
- Flutter SDK 3.9+
- Android Studio / Xcode
- Dart SDK

---

## File Statistics

- **Backend PHP Files**: 100+ controllers, models, services
- **Backend Migrations**: 30+ database migrations
- **Admin Panel React Components**: 20+ components
- **Flutter Screens**: 20+ screens
- **API Routes**: 200+ route definitions
- **Database Models**: 13 Eloquent models

---

## Notable Features

1. **Multi-tenant Architecture** - Roles scoped to congregation/parish/presbytery
2. **Meeting Minutes** - Digital minutes management
5. **Financial Tracking** - Comprehensive contribution and payment system
6. **Member Dependents** - Family member management
7. **Digital ID Cards** - QR code-based member identification
8. **Automated Notifications** - Birthday messages, payment confirmations
9. **Reporting** - Financial reports and statistics
10. **Export Capabilities** - PDF and Excel exports

---

## Configuration Files

### Backend
- `composer.json` - PHP dependencies
- `package.json` - Frontend assets (Vite)
- `.env` - Environment configuration
- `config/mpesa.php` - M-Pesa configuration

### Admin Panel
- `package.json` - Node dependencies
- `vite.config.ts` - Vite configuration
- `tailwind.config.js` - Tailwind CSS config
- `tsconfig.json` - TypeScript config

### Mobile App
- `pubspec.yaml` - Flutter dependencies
- `analysis_options.yaml` - Dart linting rules

---

## Testing & Quality

- **Backend**: PHPUnit configured
- **Linting**: ESLint for admin panel, Dart lints for Flutter
- **Type Safety**: TypeScript for admin panel, Dart for Flutter

---

## Deployment Considerations

1. **Backend**: Requires PHP 8.0+, MySQL, Composer
2. **Admin Panel**: Build with Vite, serve static files
3. **Mobile App**: Build APK/IPA for distribution
4. **Environment Variables**: Required for API keys, database, M-Pesa credentials
5. **File Storage**: Configured for member images and documents

---

## Summary

This is a comprehensive, production-ready church management system with:
- **3-tier architecture** (Backend API, Web Admin, Mobile App)
- **Role-based access control** with hierarchical permissions
- **Financial management** with M-Pesa integration
- **Geographic organization** (regions, presbyteries, parishes)
- **Member lifecycle management** (registration, profiles, dependents)
- **Administrative tools** (roles, permissions, reporting)
- **Mobile-first approach** with Flutter app

The system is designed to handle the complete operations of a church organization with multiple congregations, various leadership roles, and comprehensive member management.

