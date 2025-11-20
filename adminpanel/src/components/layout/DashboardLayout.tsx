import { useState, useEffect } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import axios from 'axios';
import Navbar from '@/components/navbar';
import Sidebar from '@/components/layout/Sidebar';
import Footer from '@/components/layout/Footer';
import { Menu, X } from 'lucide-react';

interface UserProfile {
  name: string;
  email: string;
}

const SIDEBAR_WIDTH = 256; // 256px when expanded
const SIDEBAR_COLLAPSED_WIDTH = 80; // 80px when collapsed
const NAVBAR_HEIGHT = 64; // 64px for Navbar
const HEADER_HEIGHT = 72; // additional mobile header height

const DashboardLayout = () => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(window.innerWidth >= 768);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      const token = localStorage.getItem('token');
      if (token) {
        await axios.post(`${import.meta.env.VITE_API_URL}/admin/logout`, null, {
          headers: { Authorization: `Bearer ${token}` },
        });
      }
    } catch (_) {
      // ignore
    } finally {
      localStorage.removeItem('token');
      setUser(null);
      navigate('/login');
    }
  };

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      navigate('/login');
      return;
    }
    axios.get(`${import.meta.env.VITE_API_URL}/admin/me`, {
        headers: { Authorization: `Bearer ${token}` },
      })
      .then((res) => {
        setUser(res.data);
        setLoading(false);
      })
      .catch((err) => {
        console.error('Failed to fetch user:', err);
        localStorage.removeItem('token');
        navigate('/login');
      });
  }, [navigate]);

  useEffect(() => {
    const handleResize = () => {
      const mobile = window.innerWidth < 768;
      setIsMobile(mobile);
      setSidebarOpen(!mobile);
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  if (loading || !user) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="text-lg font-medium text-gray-600 dark:text-gray-400 animate-pulse">
          Authenticating...
        </div>
      </div>
    );
  }
  
  const topPadding = isMobile ? HEADER_HEIGHT : 0;

  return (
    <>
      {/* Navbar stays fixed at top */}
      <Navbar
        user={user}
        onToggleSidebar={() => setSidebarOpen((prev) => !prev)}
        showSidebarToggle={!isMobile}
        sidebarOpen={sidebarOpen}
      />

      <div className="flex flex-col min-h-screen bg-gray-50 dark:bg-gray-900">

        {/* Fixed Sidebar with top offset */}
        <div
          className={`fixed left-0 z-20 transition-all duration-300 ease-in-out
            ${isMobile ? (sidebarOpen ? 'translate-x-0' : '-translate-x-full') : 'translate-x-0'}`}
          style={{ 
            width: isMobile ? `${SIDEBAR_WIDTH}px` : (sidebarOpen ? `${SIDEBAR_WIDTH}px` : `${SIDEBAR_COLLAPSED_WIDTH}px`), 
            top: `${NAVBAR_HEIGHT}px`, 
            height: `calc(100% - ${NAVBAR_HEIGHT}px)` 
          }}
        >
          <Sidebar 
            user={user} 
            sidebarOpen={sidebarOpen}
            isMobile={isMobile}
            onLogout={handleLogout}
            onCloseMobile={() => setSidebarOpen(false)}
          />
        </div>

        {/* Overlay for mobile */}
        {isMobile && sidebarOpen && (
          <div onClick={() => setSidebarOpen(false)} className="fixed inset-0 bg-black/40 z-10"></div>
        )}

        {/* Mobile Greeting Header */}
        {isMobile && (
          <header
            className="fixed left-0 right-0 z-10 flex items-center justify-between p-4 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md border-b border-slate-200/50 dark:border-slate-700/50 transition-all duration-300 ease-in-out"
            style={{
              top: `${NAVBAR_HEIGHT}px`,
              marginLeft: 0,
              height: `${HEADER_HEIGHT}px`,
            }}
          >
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-2 rounded-md text-gray-500 hover:text-blue-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-blue-400 dark:hover:bg-gray-700"
            >
              {sidebarOpen ? <X /> : <Menu />}
            </button>

            <div className="w-10"></div>
          </header>
        )}

        {/* Content area below fixed header */}
        <div
          className="flex flex-col flex-1 min-h-screen transition-all duration-300 ease-in-out"
          style={{
            marginLeft: isMobile ? 0 : (sidebarOpen ? `${SIDEBAR_WIDTH}px` : `${SIDEBAR_COLLAPSED_WIDTH}px`),
            paddingTop: `${topPadding}px`
          }}
        >
          <main className="flex-1 overflow-y-auto">
            <Outlet context={{ user, setUser }} />
          </main>

          <Footer />
        </div>
      </div>
    </>
  );
};

export default DashboardLayout;
