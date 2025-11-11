const Footer = () => {
  return (
    <footer className="w-full bg-white dark:bg-gray-800 border-t dark:border-gray-700 p-4 shrink-0">
      <div className="text-center text-sm text-gray-500 dark:text-gray-400" style={{ fontFamily: 'Inter, sans-serif' }}>
        <b>© {new Date().getFullYear()} Developed by Millenium Solutions East Africa Ltd. All Rights Reserved.</b>
      </div>
    </footer>
  );
};

export default Footer;