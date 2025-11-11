import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MessageSquare, Send, X, Loader2, Sparkles, ChevronDown, Cpu } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { generateResponse } from "@/lib/openai";
import pdfContent from '@/assets/sample.pdf?raw';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

const Chatbot = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([
    "What are your web development prices?",
    "Tell me about Opus Africa",
    "Tell me about your team structure",
    "What's included in maintenance plans?"
  ]);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const welcomeMessage = "👋 Hi there! I'm Opus Africa AI assistant. I can help you with information about our software development services and pricing. Feel free to ask any questions!";

  useEffect(() => {
    if (isOpen && messages.length === 0) {
      setMessages([{ role: 'assistant', content: welcomeMessage }]);
    }
  }, [isOpen]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSuggestionClick = async (text: string) => {
    setInput(text);
    const fakeEvent = new Event('submit') as any;
    await handleSubmit(fakeEvent);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMessage = input.trim();
    setInput('');
    
    // Add user message immediately
    const newUserMessage = { role: 'user' as const, content: userMessage };
    setMessages(prev => [...prev, newUserMessage]);
    setIsLoading(true);

    try {
      // Get all messages except the welcome message for context
      const contextMessages = messages.filter((_msg, index) => index !== 0);
      const response = await generateResponse([...contextMessages, newUserMessage], pdfContent);
      
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: response.answer || "I apologize, but I couldn't generate a response. Please try again."
      }]);

      // Update suggestions with the new ones from the AI
      setSuggestions(response.suggestions);
    } catch (error) {
      console.error('Error:', error);
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: "I apologize, but I encountered an error. Please try again."
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const toggleChat = () => setIsOpen(!isOpen);

  return (
    <>
      {/* Chat Button */}
      <motion.button
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        onClick={toggleChat}
        className="fixed bottom-6 right-6 z-50 bg-green-500 hover:bg-green-600 text-white p-4 rounded-full shadow-lg transition-all duration-300 hover:scale-110"
      >
        <MessageSquare className="h-6 w-6" />
      </motion.button>

      {/* Chat Window */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            transition={{ duration: 0.2 }}
            className="fixed bottom-24 right-6 w-80 h-[475px] bg-white dark:bg-gray-800 rounded-xl shadow-2xl flex flex-col overflow-hidden border border-gray-200 dark:border-gray-700"
          >
            {/* Header */}
            <div className="p-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <div className="bg-white/20 p-2 rounded-lg">
                  <Cpu className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="font-semibold">Opus Africa AI Assistant</h3>
                  <p className="text-xs text-blue-100">Your 24/7 Online Friend.</p>
                </div>
              </div>
              <button
                onClick={toggleChat}
                className="hover:bg-white/20 p-2 rounded-lg transition-colors duration-200"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50 dark:bg-gray-900">
              {messages.map((message, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                  className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {message.role === 'assistant' && (
                    <div className="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center mr-2">
                      <Sparkles className="h-4 w-4 text-white" />
                    </div>
                  )}
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl ${
                      message.role === 'user'
                        ? 'bg-blue-600 text-white rounded-br-none'
                        : 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-md rounded-bl-none'
                    }`}
                  >
                    <ReactMarkdown className="prose dark:prose-invert max-w-none text-sm">
                      {message.content}
                    </ReactMarkdown>
                  </div>
                </motion.div>
              ))}
              {isLoading && (
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="flex items-center space-x-2"
                >
                  <div className="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center">
                    <Loader2 className="h-4 w-4 text-white animate-spin" />
                  </div>
                  <div className="bg-white dark:bg-gray-800 p-3 rounded-2xl shadow-md">
                    <div className="flex space-x-2">
                      <div className="w-2 h-2 bg-blue-600 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                      <div className="w-2 h-2 bg-blue-600 rounded-full animate-bounce" style={{ animationDelay: '200ms' }} />
                      <div className="w-2 h-2 bg-blue-600 rounded-full animate-bounce" style={{ animationDelay: '400ms' }} />
                    </div>
                  </div>
                </motion.div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Suggestions */}
            <div className="p-3 bg-white dark:bg-gray-800 border-t dark:border-gray-700">
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
                {messages.length === 1 ? "Suggested questions:" : "Take a look on the suggested questions to explore more :"}
              </p>
              <div className="flex flex-wrap gap-2 max-h-24 overflow-y-auto relative">
                {suggestions.map((suggestion, index) => (
                  <button
                    key={index}
                    onClick={() => handleSuggestionClick(suggestion)}
                    className="text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 px-3 py-1 rounded-full hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200"
                  >
                    {suggestion}
                  </button>
                ))}
                <motion.div
                  className="absolute bottom-1 inset-x-0 flex justify-center"
                  animate={{ y: [0, 5, 0] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                >
                  <ChevronDown className="h-4 w-4 text-gray-500 dark:text-gray-400" />
                </motion.div>
              </div>
            </div>

            {/* Input */}
            <form onSubmit={handleSubmit} className="p-3 bg-white dark:bg-gray-800 border-t dark:border-gray-700">
              <div className="flex space-x-2">
                <textarea
                  ref={inputRef}
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Ask About Opus Africa..."
                  className="flex-1 p-2 border border-gray-200 dark:border-gray-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white resize-none placeholder-gray-400 dark:placeholder-gray-500 text-sm"
                  rows={1}
                />
                <button
                  type="submit"
                  disabled={isLoading || !input.trim()}
                  className="bg-gradient-to-r from-blue-600 to-blue-700 text-white p-2 rounded-xl hover:from-blue-700 hover:to-blue-800 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:from-blue-600 disabled:hover:to-blue-700"
                >
                  <Send className="h-5 w-5" />
                </button>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};

export default Chatbot;
