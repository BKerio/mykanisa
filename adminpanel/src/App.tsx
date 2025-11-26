// src/App.tsx
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from '@/components/theme-provider';
import RequireAuth from '@/components/requireAuth';
import DashboardLayout from '@/components/layout/DashboardLayout';
import Login from '@/pages/login';
import Dashboard from '@/pages/Dashboard';
import MembersPage from '@/pages/members';
import CongregationsPage from '@/pages/congregation';
import ContributionsPage from '@/pages/contributions';
import GroupsPage from '@/pages/groups';
import RegionsPage from '@/pages/regions';
import PresbyteriesPage from '@/pages/presbyteries';
import ParishesPage from '@/pages/parishes';
import SystemConfigPage from '@/pages/system-config';



function App() {
  return (
    <ThemeProvider defaultTheme="system">
      <Router>
        <div className='min-h-screen bg-white dark:bg-gray-900'>
          <Routes>
            
            <Route path="/login" element={<Login />} />

            <Route
              path="/dashboard"
              element={
                <RequireAuth>
                  <DashboardLayout />
                </RequireAuth>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="members" element={<MembersPage />} />
              <Route path="congregations" element={ <CongregationsPage />} />
              <Route path="contributions" element={<ContributionsPage />} />
              <Route path="groups" element={<GroupsPage />} />
              <Route path="regions" element={<RegionsPage />} />
              <Route path="presbyteries" element={<PresbyteriesPage />} />
              <Route path="parishes" element={<ParishesPage />} />
              <Route path="system-config" element={<SystemConfigPage />} />
            </Route>

            <Route path="/" element={<Navigate to="/login" replace />} />
            <Route path="*" element={<Navigate to="/login" replace />} />

          </Routes>
         
        </div>
      </Router>
    </ThemeProvider>
  );
}

export default App;