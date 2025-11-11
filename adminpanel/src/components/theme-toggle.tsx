import { Moon, Sun } from "lucide-react"
import { useTheme } from "@/components/theme-provider"
import { useEffect, useState } from "react"

export function ThemeToggle() {
  const { theme, setTheme } = useTheme()
  const [isDark, setIsDark] = useState(false)

  useEffect(() => {
    const checkDarkMode = () => {
      const isDarkMode = document.documentElement.classList.contains('dark')
      setIsDark(isDarkMode)
    }
    
    checkDarkMode()
  
    const observer = new MutationObserver(checkDarkMode)
    observer.observe(document.documentElement, { 
      attributes: true, 
      attributeFilter: ['class'] 
    })
    
    return () => observer.disconnect()
  }, [theme])

  const toggleTheme = () => {
    const newTheme = isDark ? "light" : "dark"
    setTheme(newTheme)
  }

  return (
    <button
      onClick={toggleTheme}
      className="relative inline-flex h-8 w-16 items-center rounded-full bg-gray-200 dark:bg-gray-700 transition-all duration-200 focus:outline-none hover:bg-gray-300 dark:hover:bg-gray-600"
      role="switch"
      aria-checked={isDark}
      aria-label="Toggle theme"
    >
      <div className="absolute left-2 top-1/2 -translate-y-1/2 z-0">
        <Sun className={`h-6 w-6 transition-colors duration-200 ${
          !isDark ? "text-yellow-500" : "text-gray-500"
        }`} />
      </div>
      
      <div className="absolute right-2 top-1/2 -translate-y-1/2 z-0">
        <Moon className={`h-6 w-6 transition-colors duration-200 ${
          isDark ? "text-blue-500" : "text-gray-500"
        }`} />
      </div>
      
      <div
        className={`absolute top-1 h-6 w-6 rounded-full bg-white dark:bg-gray-800 shadow-lg transform transition-all duration-200 ease-in-out z-10 ${
          isDark ? "translate-x-9" : "translate-x-1"
        }`}
      >
        <div className="flex items-center justify-center h-full">
          {isDark ? (
            <Moon className="h-4 w-4 text-blue-600" />
          ) : (
            <Sun className="h-4 w-4 text-yellow-600" />
          )}
        </div>
      </div>
    </button>
  )
}