type SnackbarProps = {
  show: boolean;
  message: string;
  type: 'success' | 'error';
};

function Snackbar({ show, message, type }: SnackbarProps) {
  return (
    <div
      className={`fixed top-5 left-1/2 transform -translate-x-1/2 z-50 px-6 py-3 rounded-md shadow-md text-white font-medium transition-all duration-500 ease-in-out
        ${show ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-5'}
        ${type === 'success' ? 'bg-green-500' : 'bg-blue-500'}`}
    >
      {message}
    </div>
  );
}

export default Snackbar;
