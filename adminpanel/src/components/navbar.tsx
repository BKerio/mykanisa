import { useState, useEffect, useCallback } from "react";
import { Link, useLocation } from "react-router-dom";
import { Menu, X, Bell } from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";
import { motion, AnimatePresence } from "framer-motion";
import NavLogo from "@/assets/icon.png"

interface User {
  name: string;
  email: string;
}

interface NavbarProps {
  user?: User | null;
}

const Navbar = ({ user }: NavbarProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);
  const location = useLocation();

  const navBarBaseHeight = scrolled ? 64 : 80;
  const totalFixedHeaderHeight = navBarBaseHeight;

  const handleScroll = useCallback(() => {
    setScrolled(window.pageYOffset > 10);
  }, []);

  useEffect(() => {
    window.addEventListener("scroll", handleScroll);
    handleScroll();
    return () => window.removeEventListener("scroll", handleScroll);
  }, [handleScroll]);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
      setScrolled(window.pageYOffset > 10);
      setIsOpen(false);
    };
    window.addEventListener("resize", handleResize);
    handleResize();
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  useEffect(() => {
    setIsOpen(false);
  }, [location]);

  const toggleMenu = () => setIsOpen((prev) => !prev);

  const renderMobileNavContent = () => (
    <div className="px-6 pt-8 pb-10 space-y-8">
      {user && (
        <div className="border-b border-slate-200 dark:border-slate-700 pb-6 space-y-4">
          <div className="flex items-center gap-4">
            <div className="relative">
              <img
                src={`https://ui-avatars.com/api/?name=${encodeURIComponent(
                  user.name
                )}&background=3b82f6&color=fff&size=48`}
                alt="User avatar"
                className="w-12 h-12 rounded-xl shadow-lg ring-2 ring-blue-500/20"
              />
              <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white dark:border-slate-900"></div>
            </div>
            <div>
              <span className="block text-lg font-bold text-slate-900 dark:text-white truncate">
                {user.name}
              </span>
              <span className="block text-sm text-slate-500 dark:text-slate-400">
                Administrator
              </span>
            </div>
          </div>
          <Link
            to="/notifications"
            onClick={() => setIsOpen(false)}
            className="flex items-center gap-3 px-4 py-3 rounded-xl text-base font-medium text-slate-700 dark:text-slate-300 transition-all duration-300 bg-gradient-to-r from-blue-50 to-blue-100/40 dark:from-slate-800 dark:to-slate-900/60 hover:from-blue-100 hover:to-blue-200/50 dark:hover:from-blue-900/40 dark:hover:to-blue-950/60"
          >
            <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
              <Bell className="h-5 w-5" />
            </div>
            <span>Notifications</span>
            <div className="ml-auto w-2 h-2 bg-red-500 rounded-full"></div>
          </Link>
        </div>
      )}

      <div className="flex justify-center">
        <ThemeToggle />
      </div>
    </div>
  );

  return (
    <>
      <header className="fixed top-0 left-0 w-full z-50">
        <motion.nav
          className={`transition-all duration-500 ${
            scrolled
              ? "bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl shadow-lg border-b border-slate-200/40 dark:border-slate-700/40"
              : "bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-transparent"
          }`}
          style={{
            height: navBarBaseHeight,
            minHeight: `${navBarBaseHeight}px`,
          }}
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-full flex justify-between items-center">
            <div className="flex items-center h-full flex-1 justify-start pl-0 sm:pl-2">
  <div className="flex items-center gap-2">
    <img
      src={NavLogo}
      alt="My Kanisa Logo"
      className={`h-${scrolled ? '12' : '14'} w-auto transition-all duration-300 drop-shadow-md`}
    />
  
    <span className="text-2xl font-bold tracking-tight bg-blue-600 bg-clip-text text-transparent select-none">
      My Kanisa Admin Panel
    </span>
  </div>
</div>



            {/* Desktop section */}
            <div className="hidden md:flex items-center gap-5">
              <ThemeToggle />
              {user && (
                <div className="flex items-center gap-4">
                  <button
                    onClick={() => alert('Notifications clicked!')}
                    className="relative p-3 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-blue-600 dark:hover:text-blue-400 transition-all duration-300 group"
                    aria-label="View notifications"
                  >
                    <Bell className="w-5 h-5 group-hover:scale-110 transition-transform duration-200" />
                    <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full border-2 border-white dark:border-slate-900"></div>
                  </button>

                  <div className="flex items-center gap-3 px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-900 hover:shadow-lg transition-all duration-300">
                    <img
                      src={`https://ui-avatars.com/api/?name=${encodeURIComponent(
                        user.name
                      )}&background=3b82f6&color=fff&size=32`}
                      alt="User avatar"
                      className="w-8 h-8 rounded-lg shadow-md"
                    />
                    <div className="text-left">
                      <p className="text-sm font-semibold text-slate-900 dark:text-white truncate max-w-32">
                        {user.name}
                      </p>
                      <p className="text-xs text-slate-500 dark:text-slate-400 truncate max-w-32">
                        Administrator
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Mobile Menu Button */}
            <div className="flex md:hidden items-center">
              <button
                onClick={toggleMenu}
                className="p-3 rounded-xl text-slate-700 dark:text-slate-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-slate-100 dark:hover:bg-slate-800 focus:outline-none transition-all duration-200"
                aria-label={isOpen ? 'Close main menu' : 'Open main menu'}
              >
                {isOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
              </button>
            </div>
          </div>
        </motion.nav>
      </header>

      <div style={{ height: `${totalFixedHeaderHeight}px` }}></div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isOpen && isMobile && (
          <motion.div
            key="mobile-nav"
            initial={{ opacity: 0, y: -15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -15 }}
            transition={{ duration: 0.35, ease: "easeOut" }}
            className="md:hidden w-full fixed left-0 z-40 bg-white/95 dark:bg-slate-900/95 backdrop-blur-lg shadow-xl border-t border-slate-200/50 dark:border-slate-700/50 rounded-b-3xl overflow-y-auto"
            style={{
              top: `${totalFixedHeaderHeight}px`,
              maxHeight: `calc(100vh - ${totalFixedHeaderHeight}px)`,
            }}
          >
            {renderMobileNavContent()}
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};

export default Navbar;
