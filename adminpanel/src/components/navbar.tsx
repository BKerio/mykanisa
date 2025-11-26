import { useState, useEffect, useCallback, useRef } from "react";
import { Link, useLocation } from "react-router-dom";
import { 
  Menu, X, Settings, LogOut, 
  User as UserIcon, ChevronDown 
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import NavLogo from "@/assets/icon.png";

// Types
interface User {
  name: string;
  email: string;
  role?: string;
}

interface NavbarProps {
  user?: User | null;
  onToggleSidebar?: () => void;
  showSidebarToggle?: boolean;
  sidebarOpen?: boolean;
}

// Animation Variants
const containerVariants = {
  hidden: { opacity: 0, y: -20 },
  visible: { 
    opacity: 1, 
    y: 0,
    transition: { 
      staggerChildren: 0.1,
      delayChildren: 0.2
    }
  }
};

const itemVariants = {
  hidden: { opacity: 0, x: -20 },
  visible: { opacity: 1, x: 0 }
};

const Navbar = ({ user, onToggleSidebar, showSidebarToggle = false, sidebarOpen }: NavbarProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);
  
  const location = useLocation();
  const profileRef = useRef<HTMLDivElement>(null);

  // Constants
  const NAV_HEIGHT_EXPANDED = 80;
  const NAV_HEIGHT_CONDENSED = 64;

  // Scroll Handler
  const handleScroll = useCallback(() => {
    setScrolled(window.pageYOffset > 20);
  }, []);

  // Click Outside for Profile Dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
        setIsProfileOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    window.addEventListener("scroll", handleScroll);
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
      setIsOpen(false);
    };
    window.addEventListener("resize", handleResize);
    
    return () => {
      window.removeEventListener("scroll", handleScroll);
      window.removeEventListener("resize", handleResize);
    };
  }, [handleScroll]);

  // Close mobile menu on route change
  useEffect(() => {
    setIsOpen(false);
  }, [location]);

  return (
    <>
      <header className="fixed top-0 left-0 w-full z-50">
        <motion.nav
          initial={false}
          animate={{
            height: scrolled ? NAV_HEIGHT_CONDENSED : NAV_HEIGHT_EXPANDED,
            backgroundColor: scrolled ? "rgba(255, 255, 255, 0.9)" : "rgba(255, 255, 255, 0.8)",
          }}
          className={`
            relative border-b backdrop-blur-xl transition-colors duration-500
            ${scrolled 
              ? "dark:bg-slate-950/90 border-slate-200/60 dark:border-slate-800/60 shadow-sm" 
              : "dark:bg-slate-950/70 border-transparent"
            }
          `}
        >
          {/* Gradient Line at Top */}
          <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-blue-500/50 to-transparent opacity-50" />

          {/* Layout Container */}
          <div className="w-full px-4 md:px-8 h-full flex justify-between items-center">
            
            {/* Left: Sidebar Toggle (Desktop) + Logo */}
            <div className="flex items-center gap-3">
              {showSidebarToggle && (
                <button
                  onClick={onToggleSidebar}
                  className="hidden md:flex items-center justify-center w-10 h-10 rounded-xl border border-slate-200 text-slate-600 hover:text-blue-600 hover:border-blue-300 transition-colors dark:border-slate-700 dark:text-slate-300 dark:hover:text-blue-400"
                  aria-label="Toggle sidebar"
                >
                  <Menu className={`h-5 w-5 transition-transform duration-300 ${sidebarOpen ? '' : 'rotate-180'}`} />
                </button>
              )}

              <Link to="/dashboard" className="flex items-center gap-3 group">
                <div className="relative">
                  <div className="absolute inset-0 bg-blue-500/20 blur-xl rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                  <img
                    src={NavLogo}
                    alt="Logo"
                    className={`relative z-10 transition-all duration-300 drop-shadow-sm ${scrolled ? 'h-8' : 'h-10'} w-auto`}
                  />
                </div>
                <div className="flex flex-col">
                  <span className="text-xl font-bold tracking-tight text-slate-900 dark:text-white leading-none group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                    My Kanisa APP
                  </span>
                  <span className={`text-[10px] font-bold uppercase tracking-widest text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 px-1.5 py-0.5 rounded-md w-fit mt-1 transition-all duration-300 ${scrolled ? 'opacity-0 h-0 overflow-hidden mt-0' : 'opacity-100'}`}>
                    Admin Panel
                  </span>
                </div>
              </Link>
            </div>

            {/* Right: Actions & Profile */}
            <div className="flex items-center gap-2 sm:gap-4">

              {/* User Profile Dropdown */}
              {user ? (
                <div className="relative z-50" ref={profileRef}>
                  <button
                    onClick={() => setIsProfileOpen(!isProfileOpen)}
                    className={`
                      flex items-center gap-3 pl-2 pr-4 py-1.5 rounded-full border transition-all duration-300
                      ${isProfileOpen 
                        ? 'bg-blue-50 border-blue-200 dark:bg-slate-800 dark:border-slate-700 ring-2 ring-blue-100 dark:ring-slate-700' 
                        : 'bg-white border-slate-200 hover:border-blue-300 dark:bg-slate-900/50 dark:border-slate-700 dark:hover:border-slate-600'
                      }
                    `}
                  >
                    <img
                      src={`https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random&color=fff`}
                      alt={user.name}
                      className="w-8 h-8 rounded-full shadow-sm ring-2 ring-white dark:ring-slate-800"
                    />
                    <div className="hidden md:block text-left">
                      <p className="text-sm font-semibold text-slate-700 dark:text-slate-200 leading-none">{user.name}</p>
                      <p className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">{user.role || "Admin"}</p>
                    </div>
                    <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform duration-300 ${isProfileOpen ? 'rotate-180' : ''}`} />
                  </button>

                  <AnimatePresence>
                    {isProfileOpen && (
                      <motion.div
                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                        transition={{ duration: 0.2 }}
                        className="absolute right-0 mt-2 w-64 bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-700 overflow-hidden ring-1 ring-black/5"
                      >
                        <div className="p-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50">
                          <p className="text-sm font-medium text-slate-900 dark:text-white">Signed in as</p>
                          <p className="text-sm text-slate-500 dark:text-slate-400 truncate">{user.email}</p>
                        </div>
                        <div className="p-2">
                          {[
                            { icon: UserIcon, label: "Profile" },
                            { icon: Settings, label: "Settings" },
                          ].map((item) => (
                            <Link
                              key={item.label}
                              to="#"
                              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                            >
                              <item.icon className="w-4 h-4" />
                              {item.label}
                            </Link>
                          ))}
                        </div>
                        <div className="p-2 border-t border-slate-100 dark:border-slate-800">
                          <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors">
                            <LogOut className="w-4 h-4" />
                            Sign out
                          </button>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              ) : (
                <div className="hidden md:block">
                  <Link to="/login" className="px-5 py-2.5 rounded-full bg-blue-600 text-white text-sm font-semibold shadow-lg shadow-blue-500/30 hover:bg-blue-700 hover:scale-105 transition-all duration-200">
                    Login
                  </Link>
                </div>
              )}

              {/* Mobile Menu Toggle */}
              <div className="md:hidden flex items-center ml-2">
                <button
                  onClick={() => setIsOpen(!isOpen)}
                  className="p-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors"
                >
                  <AnimatePresence mode="wait">
                    {isOpen ? (
                      <motion.div key="close" initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }}>
                        <X className="h-6 w-6" />
                      </motion.div>
                    ) : (
                      <motion.div key="menu" initial={{ rotate: 90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: -90, opacity: 0 }}>
                        <Menu className="h-6 w-6" />
                      </motion.div>
                    )}
                  </AnimatePresence>
                </button>
              </div>
            </div>
          </div>
        </motion.nav>
      </header>

      {/* Spacer to prevent content jump */}
      <div style={{ height: scrolled ? NAV_HEIGHT_CONDENSED : NAV_HEIGHT_EXPANDED }} className="transition-all duration-500" />

      {/* Mobile Navigation Menu */}
      <AnimatePresence>
        {isOpen && isMobile && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsOpen(false)}
              className="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-40 md:hidden"
            />
            <motion.div
              variants={containerVariants}
              initial="hidden"
              animate="visible"
              exit={{ opacity: 0, y: -20, transition: { duration: 0.2 } }}
              className="fixed top-0 left-0 w-full z-40 bg-white/90 dark:bg-slate-950/90 backdrop-blur-xl border-b border-slate-200 dark:border-slate-800 shadow-2xl md:hidden rounded-b-3xl"
              style={{ 
                paddingTop: scrolled ? NAV_HEIGHT_CONDENSED + 20 : NAV_HEIGHT_EXPANDED + 20 
              }}
            >
              <div className="px-6 pb-8 space-y-6">
                
                {/* Mobile User Info */}
                {user && (
                  <motion.div variants={itemVariants} className="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-slate-800 dark:to-slate-900 p-4 rounded-2xl border border-blue-100 dark:border-slate-700">
                    <div className="flex items-center gap-4">
                      <img
                        src={`https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=3b82f6&color=fff`}
                        alt="User"
                        className="w-12 h-12 rounded-full border-4 border-white dark:border-slate-800 shadow-md"
                      />
                      <div>
                        <h3 className="font-bold text-lg text-slate-900 dark:text-white">{user.name}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{user.email}</p>
                      </div>
                    </div>
                    <div className="mt-4 grid grid-cols-2 gap-3">
                      <button className="flex items-center justify-center gap-2 py-2 rounded-xl bg-white dark:bg-slate-800 shadow-sm text-sm font-medium text-slate-700 dark:text-slate-300">
                        <Settings className="h-4 w-4" /> Settings
                      </button>
                      <button className="flex items-center justify-center gap-2 py-2 rounded-xl bg-white dark:bg-slate-800 shadow-sm text-sm font-medium text-red-600">
                        <LogOut className="h-4 w-4" /> Sign Out
                      </button>
                    </div>
                  </motion.div>
                )}

                {/* Mobile Menu Links
                <motion.div variants={itemVariants} className="space-y-1">
                  <p className="px-4 text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Menu</p>
                  {['Dashboard', 'Notifications', 'Analytics', 'Users'].map((item) => (
                     <Link
                      key={item}
                      to={`/${item.toLowerCase()}`}
                      onClick={() => setIsOpen(false)}
                      className="flex items-center justify-between px-4 py-3 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                    >
                      <span className="font-medium text-lg">{item}</span>
                      <div className="w-1 h-1 bg-slate-300 rounded-full" />
                    </Link>
                  ))}
                </motion.div> */}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  );
};

export default Navbar;