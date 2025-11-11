import { Link, useLocation } from 'react-router-dom';
import Swal from 'sweetalert2';
import {
  ChurchIcon,
  LayoutDashboard,
  LogOut,
  LucideUserCircle2,
  Users,
  MapPin,
  Building2,
  Church,
} from 'lucide-react';

interface UserProfile {
  name: string;
  email: string;
}

interface SidebarProps {
  user: UserProfile;
  sidebarOpen: boolean;
  isMobile: boolean;
  onLogout: () => void;
  onCloseMobile: () => void;
}

const Sidebar = ({ user, sidebarOpen, isMobile, onLogout, onCloseMobile }: SidebarProps) => {
  const location = useLocation();

  const sidebarNavLinks = [
    { name: 'Dashboard', icon: LayoutDashboard, path: '/dashboard' },
    { name: 'Registered Members', icon: LucideUserCircle2, path: '/dashboard/members' },
    { name: 'View All Congregation', icon: ChurchIcon, path: '/dashboard/congregations' },
    { name: 'View Contributions', icon: ChurchIcon, path: '/dashboard/contributions' },
    { name: 'Manage Church Groups', icon: Users, path: '/dashboard/groups' },
    { name: 'Manage Regions', icon: MapPin, path: '/dashboard/regions' },
    { name: 'Manage Presbyteries', icon: Building2, path: '/dashboard/presbyteries' },
    { name: 'Manage Parishes', icon: Church, path: '/dashboard/parishes' },

  ];

  const handleLogout = async () => {
    const result = await Swal.fire({
      title: 'Are you sure?',
      text: 'You will be logged out from your session.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, logout',
      cancelButtonText: 'Cancel',
    });

    if (result.isConfirmed) {
      onLogout();
    }
  };

  return (
    <aside
      className={`
        bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-800 dark:to-slate-900
        shadow-2xl border-r border-slate-200/50 dark:border-slate-700/50 transition-all duration-300 z-50 flex flex-col
        ${isMobile ? 'fixed top-0 left-0 h-full' : 'relative h-full'}
        ${isMobile && !sidebarOpen ? '-translate-x-full' : ''}
      `}
    >
      <div className="flex flex-col h-full overflow-y-auto scrollbar-thin scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-600 scrollbar-track-transparent">

        {/* Enhanced Profile Header */}
        <div className="sticky top-0 z-10 bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm border-b border-slate-200/50 dark:border-slate-700/50 p-4">
          <div className="flex items-center gap-3">
            <div className="relative flex-shrink-0">
              <img
                src={`https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=3b82f6&color=fff&size=40`}
                alt="avatar"
                className="w-10 h-10 rounded-xl shadow-lg ring-2 ring-blue-500/20"
              />
              <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-slate-800"></div>
            </div>
            <div className={`overflow-hidden transition-all duration-300 ${!sidebarOpen && 'md:opacity-0 md:w-0'}`}>
              <h3 className="font-bold text-slate-900 dark:text-white truncate text-base">{user.name}</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 truncate">{user.email}</p>
              <div className="flex items-center gap-1 mt-1">
                <div className="w-1.5 h-1.5 bg-green-500 rounded-full"></div>
                <span className="text-xs text-green-600 dark:text-green-400 font-medium">Online</span>
              </div>
            </div>
          </div>
        </div>

        {/* Enhanced Navigation Links */}
        <nav className="flex-grow p-3 space-y-1">
          {sidebarNavLinks.map((link) => {
            const isActive = location.pathname === link.path;
            return (
              <Link
                key={link.name}
                to={link.path}
                className={`group flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 relative overflow-hidden
                  ${isActive
                    ? 'bg-gradient-to-r from-blue-500 to-indigo-600 text-white shadow-lg shadow-blue-500/25'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-700/50 dark:hover:text-white'}
                  ${!sidebarOpen && 'md:justify-center md:px-2'}
                `}
                onClick={isMobile ? onCloseMobile : undefined}
                title={!sidebarOpen ? link.name : undefined}
              >
                {/* Active indicator */}
                {isActive && (
                  <span className="absolute left-0 top-0 bottom-0 w-1 bg-white rounded-r-full shadow-lg"></span>
                )}
                
                {/* Icon container */}
                <div className={`flex items-center justify-center w-8 h-8 rounded-lg transition-all duration-200 flex-shrink-0 ${
                  isActive 
                    ? 'bg-white/20' 
                    : 'bg-slate-100 dark:bg-slate-700 group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30'
                }`}>
                  <link.icon className={`h-4 w-4 transition-all duration-200 ${
                    isActive 
                      ? 'text-white' 
                      : 'text-slate-600 dark:text-slate-300 group-hover:text-blue-600 dark:group-hover:text-blue-400'
                  } group-hover:scale-110`} />
                </div>
                
                {/* Text */}
                <span className={`font-medium text-sm transition-all duration-300 ${
                  !sidebarOpen && 'md:w-0 md:opacity-0 md:overflow-hidden'
                }`}>
                  {link.name}
                </span>
                
                {/* Hover indicator */}
                {!isActive && (
                  <div className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 ml-auto">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                  </div>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Enhanced Logout */}
        <div className="p-3 border-t border-slate-200/50 dark:border-slate-700/50">
          <button
            onClick={handleLogout}
            className={`
              group w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 relative overflow-hidden
              text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:text-red-400 hover:text-red-700 dark:hover:text-red-300
              ${!sidebarOpen && 'md:justify-center md:px-2'}
            `}
            title={!sidebarOpen ? 'Logout' : undefined}
          >
            {/* Icon container */}
            <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-red-100 dark:bg-red-900/30 group-hover:bg-red-200 dark:group-hover:bg-red-900/40 transition-all duration-200 flex-shrink-0">
              <LogOut className="h-4 w-4 transition-all duration-200 group-hover:scale-110" />
            </div>
            
            {/* Text */}
            <span className={`font-medium text-sm transition-all duration-300 ${
              !sidebarOpen && 'md:w-0 md:opacity-0 md:overflow-hidden'
            }`}>
              Logout
            </span>
            
            {/* Hover indicator */}
            <div className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 ml-auto">
              <div className="w-1.5 h-1.5 bg-red-500 rounded-full"></div>
            </div>
          </button>
        </div>
      </div>
    </aside>
  );
};

export default Sidebar;
