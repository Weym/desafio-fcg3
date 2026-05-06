/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  Home, 
  MessageSquare, 
  FileText, 
  Bell, 
  Headset, 
  Menu, 
  Sun,
  Moon,
  ArrowLeft,
  ChevronRight,
  Download,
  Search,
  Upload,
  Plus,
  Clock,
  CheckCircle,
  AlertCircle,
  Smartphone,
  Mail,
  Bot,
  Users,
  GraduationCap,
  Calendar,
  AlertTriangle,
  ArrowRight,
  Settings,
  Megaphone,
  LayoutDashboard,
  LogOut
} from 'lucide-react';
import { 
  ScreenId, 
  NOTIFICATIONS, 
  CHATS, 
  DOCUMENTS,
  MOCK_MESSAGES,
  REQUESTABLE_DOCUMENTS
} from './types';

// Reusable Components
const GlassCard = ({ children, className = "" }: { children: React.ReactNode, className?: string, key?: any }) => (
  <div className={`glass-panel rounded-lg p-4 soft-shadow ${className}`}>
    {children}
  </div>
);

const PillButton = ({ 
  children, 
  onClick, 
  variant = 'primary', 
  className = "",
  disabled = false
}: { 
  children: React.ReactNode, 
  onClick?: () => void, 
  variant?: 'primary' | 'secondary' | 'ghost' | 'error',
  className?: string,
  disabled?: boolean
}) => {
  const styles = {
    primary: "bg-primary text-on-primary shadow-md hover:opacity-90 disabled:opacity-50",
    secondary: "bg-secondary-container text-on-secondary-container hover:opacity-80 disabled:opacity-50",
    ghost: "bg-surface-container text-on-surface-variant border border-outline-variant hover:bg-surface-container-high disabled:opacity-50",
    error: "bg-error text-on-error shadow-md hover:opacity-90 disabled:opacity-50"
  };
  
  return (
    <button 
      disabled={disabled}
      onClick={onClick}
      className={`px-6 py-2 rounded-full font-semibold transition-all active:scale-95 flex items-center justify-center gap-2 ${styles[variant]} ${className}`}
    >
      {children}
    </button>
  );
};

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<ScreenId>('login');
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [selectedChatId, setSelectedChatId] = useState<string | null>(null);
  
  // Dynamic Data States
  const [notifications, setNotifications] = useState(NOTIFICATIONS);
  const [documents, setDocuments] = useState(DOCUMENTS);
  const [docFilter, setDocFilter] = useState<'all' | 'Pendentes' | 'Prontos'>('all');

  // Actions
  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, isUnread: false })));
  };

  // Layout Components
  const TopAppBar = ({ title, showBack = false }: { title: string, showBack?: boolean }) => (
    <header className="fixed top-0 left-0 right-0 h-16 glass-panel z-50 flex items-center justify-between px-5 shadow-sm">
      <div className="flex items-center gap-2">
        {showBack ? (
          <button onClick={() => {
            if (currentScreen === 'chat-detail') {
              setCurrentScreen('chat');
            } else if (currentScreen === 'document-request') {
              setCurrentScreen('documents');
            } else {
              setCurrentScreen('home');
            }
          }} className="p-2 hover:bg-surface-container rounded-full text-primary transition-colors">
            <ArrowLeft size={24} />
          </button>
        ) : (
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
            <GraduationCap size={24} />
          </div>
        )}
        <h1 className="font-sans text-xl font-bold text-primary tracking-tight">{title}</h1>
      </div>
      <div className="flex items-center gap-1">
        <button 
          onClick={() => setIsDarkMode(!isDarkMode)}
          className="p-2 hover:bg-surface-container rounded-full text-primary transition-colors"
        >
          {isDarkMode ? <Sun size={24} /> : <Moon size={24} strokeWidth={2.5} />}
        </button>
        <button
          onClick={() => setCurrentScreen('login')}
          className="p-2 hover:bg-error/10 rounded-full text-error transition-colors"
          title="Sair"
        >
          <LogOut size={22} />
        </button>
      </div>
    </header>
  );

  const BottomNavBar = () => {
    const isManager = currentScreen.startsWith('manager');
    const isChatDetail = currentScreen === 'chat-detail';

    if (isChatDetail) return null;
    
    const studentItems = [
      { id: 'home', icon: Home, label: 'Início' },
      { id: 'chat', icon: MessageSquare, label: 'Chat' },
      { id: 'documents', icon: FileText, label: 'Docs' },
      { id: 'notifications', icon: Bell, label: 'Avisos' },
      { id: 'support', icon: Headset, label: 'Suporte' }
    ];

    const managerItems = [
      { id: 'manager', icon: LayoutDashboard, label: 'Painel' },
      { id: 'manager-chats', icon: MessageSquare, label: 'Intervenção' },
      { id: 'manager-scheduling', icon: Calendar, label: 'Recursos' },
      { id: 'manager-insights', icon: Megaphone, label: 'Insights' },
      { id: 'login', icon: LogOut, label: 'Sair' }
    ];

    const items = isManager ? managerItems : studentItems;

    return (
      <nav className="fixed bottom-0 left-0 right-0 h-20 glass-panel z-50 flex justify-around items-center px-4 safe-pb shadow-lg border-t border-white/40">
        {items.map((item) => (
          <button
            key={item.id}
            onClick={() => setCurrentScreen(item.id as ScreenId)}
            className={`flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-all ${
              currentScreen === item.id 
                ? "bg-primary text-on-primary scale-90" 
                : "text-on-surface-variant hover:bg-surface-container"
            }`}
          >
            <item.icon size={24} strokeWidth={currentScreen === item.id ? 2.5 : 2} />
            <span className="text-[10px] font-bold uppercase tracking-wider">{item.label}</span>
          </button>
        ))}
      </nav>
    );
  };

  // Screen Components
  const LoginScreen = () => (
    <div className="min-h-screen bg-surface-container-low flex items-center justify-center p-6 relative overflow-hidden">
      {/* Ambient backgrounds */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-primary-container/30 rounded-full blur-[100px]" />
      <div className="absolute top-1/3 -right-20 w-80 h-80 bg-secondary-container/30 rounded-full blur-[80px]" />
      
      <motion.main 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative z-10 w-full max-w-sm glass-panel p-8 rounded-2xl shadow-xl flex flex-col items-center"
      >
        <header className="flex flex-col items-center mb-8">
          <div className="bg-primary-container text-on-primary-container p-6 rounded-2xl shadow-inner rotate-3 transition-transform hover:rotate-0 mb-4">
            <GraduationCap size={48} className="-rotate-3" />
          </div>
          <h1 className="font-sans text-2xl font-bold text-primary tracking-widest uppercase">Alpha Connect</h1>
        </header>

        <section className="text-center mb-8">
          <h2 className="text-3xl font-bold text-on-surface mb-2">Entrar</h2>
          <p className="text-on-surface-variant font-medium">Informe seu email acadêmico...</p>
        </section>

        <form className="w-full space-y-6" onSubmit={(e) => { e.preventDefault(); setCurrentScreen('verify-code'); }}>
          <div className="flex items-center bg-surface-container-high/50 border border-outline-variant/30 rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-primary/20 transition-all">
            <Mail size={20} className="text-on-surface-variant mr-3" />
            <input 
              type="email" 
              placeholder="Email acadêmico" 
              className="flex-1 bg-transparent border-none p-0 outline-none font-medium text-on-surface placeholder:text-on-surface-variant/50"
              required
            />
          </div>
          
          <PillButton className="w-full py-4 text-lg">
            Enviar código
            <ArrowRight size={20} />
          </PillButton>
        </form>
        
        <button 
          onClick={() => setCurrentScreen('manager-login')}
          className="mt-8 text-on-surface-variant text-sm font-semibold hover:text-primary transition-colors"
        >
          Acessar como Gestor
        </button>
      </motion.main>
    </div>
  );

  const ManagerLoginScreen = () => (
    <div className="min-h-screen bg-surface-container-low flex items-center justify-center p-6 relative overflow-hidden">
      {/* Ambient backgrounds */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-primary-container/30 rounded-full blur-[100px]" />
      <div className="absolute top-1/3 -right-20 w-80 h-80 bg-secondary-container/30 rounded-full blur-[80px]" />
      
      <motion.main 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative z-10 w-full max-w-sm glass-panel p-8 rounded-2xl shadow-xl flex flex-col items-center"
      >
        <header className="flex flex-col items-center mb-8">
          <div className="bg-tertiary-container text-on-tertiary-container p-6 rounded-2xl shadow-inner rotate-3 transition-transform hover:rotate-0 mb-4">
            <Settings size={48} className="-rotate-3" />
          </div>
          <h1 className="font-sans text-2xl font-bold text-tertiary tracking-widest uppercase text-center">Portal Gestão</h1>
        </header>

        <section className="text-center mb-8">
          <h2 className="text-3xl font-bold text-on-surface mb-2">Entrar</h2>
          <p className="text-on-surface-variant font-medium">Informe seu email corporativo...</p>
        </section>

        <form className="w-full space-y-6" onSubmit={(e) => { e.preventDefault(); setCurrentScreen('manager-verify-code'); }}>
          <div className="flex items-center bg-surface-container-high/50 border border-outline-variant/30 rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-tertiary/20 transition-all">
            <Mail size={20} className="text-on-surface-variant mr-3" />
            <input 
              type="email" 
              placeholder="Email gestor" 
              className="flex-1 bg-transparent border-none p-0 outline-none font-medium text-on-surface placeholder:text-on-surface-variant/50"
              required
            />
          </div>
          
          <PillButton className="w-full py-4 text-lg !bg-tertiary !text-on-tertiary" variant="primary">
            Enviar código
            <ArrowRight size={20} />
          </PillButton>
        </form>
        
        <button 
          onClick={() => setCurrentScreen('login')}
          className="mt-8 text-on-surface-variant text-sm font-semibold hover:text-tertiary transition-colors flex items-center gap-2"
        >
          <ArrowLeft size={16} /> Voltar para Aluno
        </button>
      </motion.main>
    </div>
  );

  const VerifyCodeScreen = ({ isManager = false }: { isManager?: boolean }) => {
    const [code, setCode] = useState(['', '', '', '', '', '']);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

    const handleInput = (index: number, value: string) => {
      // Remove any non-digits
      const digitStr = value.replace(/\D/g, '');
      
      if (digitStr.length > 1) {
        // Handle paste across multiple fields
        const pasted = digitStr.slice(0, 6).split('');
        const newCode = [...code];
        
        // Fill from current index onwards
        let pasteIndex = 0;
        for (let i = index; i < 6 && pasteIndex < pasted.length; i++) {
          newCode[i] = pasted[pasteIndex];
          pasteIndex++;
        }
        
        setCode(newCode);
        
        // Focus next empty input or the last one
        const nextIndex = Math.min(index + pasted.length, 5);
        inputRefs.current[nextIndex]?.focus();
        return;
      }

      // Single digit entry
      const newCode = [...code];
      newCode[index] = digitStr.slice(0, 1);
      setCode(newCode);

      if (digitStr && index < 5) {
        inputRefs.current[index + 1]?.focus();
      }
    };

    const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
      // Allow control keys (Backspace, Tab, Delete, Arrows, etc), meta/ctrl for paste
      if (['Backspace', 'Delete', 'Tab', 'Escape', 'Enter', 'ArrowLeft', 'ArrowRight'].includes(e.key) || e.ctrlKey || e.metaKey) {
        if (e.key === 'Backspace' && !code[index] && index > 0) {
          inputRefs.current[index - 1]?.focus();
        }
        return;
      }
      
      // Block non-numeric characters
      if (!/^[0-9]$/.test(e.key)) {
        e.preventDefault();
      }
    };

    return (
      <div className="min-h-screen bg-surface-container-low flex items-center justify-center p-6 relative overflow-hidden">
        {/* Ambient backgrounds */}
        <div className="absolute -top-40 -left-40 w-96 h-96 bg-primary-container/30 rounded-full blur-[100px]" />
        <div className="absolute top-1/3 -right-20 w-80 h-80 bg-secondary-container/30 rounded-full blur-[80px]" />
        
        <motion.main 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="relative z-10 w-full max-w-sm glass-panel p-8 rounded-2xl shadow-xl flex flex-col items-center"
        >
          <header className="flex flex-col items-center mb-8">
            <div className={`p-6 rounded-2xl shadow-inner rotate-3 transition-transform hover:rotate-0 mb-4 ${isManager ? 'bg-tertiary-container text-on-tertiary-container' : 'bg-primary-container text-on-primary-container'}`}>
              <Mail size={48} className="-rotate-3" />
            </div>
            <h1 className={`font-sans text-xl font-bold tracking-widest uppercase text-center ${isManager ? 'text-tertiary' : 'text-primary'}`}>Código de Acesso</h1>
          </header>

          <section className="text-center mb-8">
            <p className="text-on-surface-variant font-medium leading-relaxed">Insira o código de 6 dígitos enviado para o seu email (000000).</p>
          </section>

          <form className="w-full space-y-6" onSubmit={(e) => { 
            e.preventDefault(); 
            setCurrentScreen(isManager ? 'manager' : 'home'); 
          }}>
            <div className="flex justify-between gap-1 sm:gap-2">
              {code.map((digit, index) => (
                <input
                  key={index}
                  autoFocus={index === 0}
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]*"
                  maxLength={6}
                  value={digit}
                  onChange={(e) => handleInput(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  ref={(el) => (inputRefs.current[index] = el)}
                  className={`w-10 sm:w-12 h-12 sm:h-14 bg-surface-container-high/50 border border-outline-variant/30 rounded-xl text-center text-xl sm:text-3xl font-bold text-on-surface focus:outline-none focus:ring-2 transition-all ${isManager ? 'focus:ring-tertiary/50 focus:border-tertiary' : 'focus:ring-primary/50 focus:border-primary'}`}
                  required
                />
              ))}
            </div>
            
            <PillButton className={`w-full py-4 text-lg ${isManager ? '!bg-tertiary !text-on-tertiary' : ''}`}>
              Verificar Código
              <ArrowRight size={20} />
            </PillButton>
          </form>
          
          <button 
            onClick={() => setCurrentScreen(isManager ? 'manager-login' : 'login')}
            className={`mt-8 text-on-surface-variant text-sm font-semibold transition-colors flex items-center gap-2 ${isManager ? 'hover:text-tertiary' : 'hover:text-primary'}`}
          >
            <ArrowLeft size={16} /> Voltar
          </button>
        </motion.main>
      </div>
    );
  };

  const StudentHomeScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-8 max-w-3xl mx-auto">
      <section>
        <h2 className="text-3xl font-bold text-on-surface mb-1">Olá, João!</h2>
        <p className="text-on-surface-variant font-medium">Pronto para mais um dia de aprendizado?</p>
      </section>

      <div className="relative w-full h-48 rounded-2xl overflow-hidden soft-shadow">
        <img 
          src="https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=2071&auto=format&fit=crop" 
          alt="Student" 
          className="w-full h-full object-cover" 
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent p-6 flex flex-col justify-end">
          <span className="bg-primary-container text-on-primary-container px-3 py-1 rounded-full text-xs font-bold w-fit mb-2">Destaque</span>
          <h3 className="text-white text-xl font-bold leading-tight">Novo curso de Lógica de Programação disponível.</h3>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <GlassCard className="flex flex-col gap-4 relative overflow-hidden bg-surface-container-lowest">
          <div className="absolute -right-4 -top-4 w-20 h-20 bg-primary-container/20 rounded-full blur-xl" />
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-full bg-primary-container text-on-primary-container">
              <Bot size={24} />
            </div>
            <div>
              <h4 className="font-bold text-on-surface">Chatbot Alpha</h4>
              <span className="text-xs text-on-surface-variant">Assistente Virtual</span>
            </div>
          </div>
          <p className="text-sm text-on-surface-variant">Tire dúvidas rápidas sobre o sistema e prazos.</p>
          <div className="mt-auto bg-surface-container rounded-lg p-2 flex justify-between items-center text-xs">
            <span className="text-on-surface-variant">Última interação:</span>
            <span className="font-bold text-primary">Hoje, 10:30</span>
          </div>
        </GlassCard>

        <GlassCard className="flex flex-col gap-4 relative overflow-hidden bg-surface-container-lowest">
          <div className="absolute -right-4 -top-4 w-20 h-20 bg-secondary-container/20 rounded-full blur-xl" />
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-full bg-secondary-container text-on-secondary-container">
              <Calendar size={24} />
            </div>
            <div>
              <h4 className="font-bold text-on-surface">Agendamentos</h4>
              <span className="text-xs text-on-surface-variant">Próximos Eventos</span>
            </div>
          </div>
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-primary" />
              <span className="text-sm text-on-surface">Reunião de Orientação</span>
            </div>
          </div>
          <div className="mt-auto border-l-4 border-primary bg-surface-container rounded-lg p-2 text-xs">
            <span className="text-on-surface-variant block">Próximo:</span>
            <span className="font-bold text-on-surface">Amanhã, 14:00</span>
          </div>
        </GlassCard>
      </div>

      <section>
        <h3 className="font-bold text-lg mb-4 text-on-surface">Ações Rápidas</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: 'Solicitar documento', icon: FileText, screen: 'document-request', classLabel: 'bg-primary/10 text-primary group-hover:bg-primary group-hover:text-on-primary' },
            { label: 'Conversar com Mentor', icon: MessageSquare, screen: 'chat', classLabel: 'bg-secondary/10 text-secondary group-hover:bg-secondary group-hover:text-on-secondary' },
            { label: 'Grade Curricular', icon: LayoutDashboard, screen: 'documents', classLabel: 'bg-tertiary/10 text-tertiary group-hover:bg-tertiary group-hover:text-on-tertiary' },
            { label: 'Boleto Digital', icon: Smartphone, screen: 'support', classLabel: 'bg-error/10 text-error group-hover:bg-error group-hover:text-on-error' }
          ].map((action, i) => (
            <button 
              key={i}
              onClick={() => setCurrentScreen(action.screen as ScreenId)}
              className="flex items-center gap-3 p-4 rounded-xl bg-surface-container-lowest glass-panel hover:scale-[1.02] transition-all group border border-outline-variant/30"
            >
              <div className={`p-2.5 rounded-lg transition-colors ${action.classLabel}`}>
                <action.icon size={20} />
              </div>
              <span className="text-xs font-bold text-on-surface leading-tight text-left">{action.label}</span>
            </button>
          ))}
        </div>
      </section>
    </div>
  );

  const SupportScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-8 max-w-3xl mx-auto">
      <header className="text-center">
        <div className="w-20 h-20 rounded-full bg-primary-container text-on-primary-container mx-auto flex items-center justify-center mb-4 pillowy-shadow">
          <Headset size={40} />
        </div>
        <h2 className="text-3xl font-bold text-primary">Suporte</h2>
        <p className="text-on-surface-variant text-lg">Como podemos ajudar você hoje?</p>
      </header>

      <div className="rounded-2xl overflow-hidden aspect-video relative soft-shadow">
        <img 
          src="https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?q=80&w=2072&auto=format&fit=crop" 
          alt="Support" 
          className="w-full h-full object-cover" 
        />
        <div className="absolute inset-0 bg-primary/20 dark:bg-black/40" />
      </div>

      <div className="space-y-4">
        {[
          { icon: Smartphone, title: 'Conversar no WhatsApp', sub: 'Assistente virtual rápido', color: 'bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400' },
          { icon: Headset, title: 'Ligar para a Faculdade', sub: 'Atendimento telefônico', color: 'bg-surface-container text-primary dark:bg-surface-container-high' },
          { icon: Mail, title: 'Enviar E-mail', sub: 'Suporte acadêmico', color: 'bg-secondary-container text-secondary dark:bg-secondary-container/20 dark:text-secondary' }
        ].map((item, i) => (
          <button key={i} className="w-full bg-surface-container-lowest glass-panel p-4 flex items-center gap-4 hover:scale-[1.02] transition-all group overflow-hidden relative">
            <div className={`w-12 h-12 rounded-full flex items-center justify-center ${item.color}`}>
              <item.icon size={24} />
            </div>
            <div className="text-left flex-1">
              <h4 className="font-bold text-on-surface">{item.title}</h4>
              <p className="text-sm text-on-surface-variant">{item.sub}</p>
            </div>
            <ChevronRight className="text-outline-variant group-hover:text-primary transition-colors" />
          </button>
        ))}
      </div>

      <GlassCard className="text-center p-6 bg-surface-container-lowest/40">
        <Clock className="mx-auto mb-2 text-outline" />
        <h5 className="uppercase text-[10px] font-bold tracking-widest text-on-surface-variant mb-1">Horário de Atendimento</h5>
        <p className="font-bold text-on-surface">Segunda a Sexta, das 08h às 21h</p>
      </GlassCard>
    </div>
  );

  const NotificationsScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-6 max-w-3xl mx-auto">
      <div className="flex justify-between items-end mb-2">
        <div>
          <h2 className="text-3xl font-bold text-on-surface">Notificações</h2>
          <p className="text-on-surface-variant text-sm mt-1">Você tem {notifications.filter(n => n.isUnread).length} novos alertas.</p>
        </div>
        <button 
          onClick={markAllAsRead}
          className="text-xs font-bold text-primary uppercase tracking-widest hover:opacity-70 px-3 py-1.5 rounded-full bg-primary/10 transition-colors"
        >
          Marcar lidas
        </button>
      </div>

      {/* Hero Decorative Banner */}
      <div className="relative w-full h-32 rounded-2xl overflow-hidden pillowy-shadow mb-4 flex items-center p-6">
        <div className="absolute inset-0 bg-primary-container/80 backdrop-blur-sm z-10 dark:bg-primary-container/40" />
        <div className="absolute inset-0 z-0">
          <img 
            src="https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?q=80&w=2070&auto=format&fit=crop" 
            alt="Abstract background"
            className="w-full h-full object-cover opacity-60"
          />
        </div>
        <div className="relative z-20 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-white/50 backdrop-blur-md flex items-center justify-center text-primary shadow-sm">
            <Megaphone size={24} fill="currentColor" />
          </div>
          <div>
            <h3 className="font-bold text-on-primary-container">Fique por dentro!</h3>
            <p className="text-xs text-on-primary-container/80">Acompanhe seus prazos e documentos aqui.</p>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        {notifications.map((notif) => (
          <motion.article 
            key={notif.id}
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            className={`p-5 rounded-xl relative flex items-start gap-4 transition-all hover:scale-[1.01] cursor-pointer ${
              notif.isUnread ? "bg-surface-container-lowest glass-panel border-primary/20" : "bg-surface-container-low/50 opacity-80"
            }`}
          >
            {notif.isUnread && <div className="absolute top-5 right-5 w-2 h-2 rounded-full bg-primary animate-pulse" />}
            <div className={`w-12 h-12 rounded-full flex items-center justify-center shrink-0 shadow-sm ${
              notif.type === 'doc' ? "bg-tertiary-container text-on-tertiary-container" :
              notif.type === 'msg' ? "bg-secondary-container text-on-secondary-container" :
              "bg-surface-container-high text-on-surface-variant"
            }`}>
              {notif.type === 'doc' ? <FileText size={24} /> :
               notif.type === 'msg' ? <MessageSquare size={24} /> :
               notif.type === 'event' ? <Calendar size={24} /> :
               <Settings size={24} />}
            </div>
            <div className="flex-1 pr-4">
              <div className="flex items-center gap-2 mb-1">
                <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded ${
                  notif.type === 'doc' ? "bg-tertiary-container/30 text-tertiary" :
                  notif.type === 'msg' ? "bg-secondary-container/30 text-secondary" :
                  "bg-surface-variant text-on-surface-variant"
                }`}>{notif.category}</span>
                <span className="text-[12px] text-outline">{notif.time}</span>
              </div>
              <h4 className="font-bold text-sm leading-tight mb-1 text-on-surface">{notif.title}</h4>
              <p className="text-xs text-on-surface-variant line-clamp-2">{notif.description}</p>
            </div>
          </motion.article>
        ))}
      </div>
    </div>
  );

  const DocumentsScreen = () => {
    const filteredDocs = docFilter === 'all' 
      ? documents 
      : documents.filter(doc => {
          if (docFilter === 'Pendentes') return doc.status === 'Pendente' || doc.status === 'Processando';
          if (docFilter === 'Prontos') return doc.status === 'Pronto';
          return true;
        });

    return (
      <div className="pt-24 pb-28 px-5 space-y-6 max-w-3xl mx-auto">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-3xl font-bold text-on-surface">Documentos</h2>
          <button 
            onClick={() => setCurrentScreen('document-request')}
            className="w-12 h-12 rounded-xl bg-primary text-on-primary flex items-center justify-center shadow-md active:scale-95 transition-all"
            title="Solicitar Documento"
          >
            <Plus size={24} />
          </button>
        </div>

        <div className="w-full h-44 rounded-2xl overflow-hidden relative soft-shadow group">
          <img 
            src="https://images.unsplash.com/photo-1568667256549-094345857637?q=80&w=2030&auto=format&fit=crop" 
            alt="Documents" 
            className="w-full h-full object-cover transition-transform group-hover:scale-110 duration-700" 
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex items-end p-6">
            <span className="text-xs font-bold text-white/80 uppercase tracking-widest">Repositório Oficial</span>
          </div>
        </div>

        <div className="bg-surface-container-low p-1.5 rounded-2xl">
          <div className="flex gap-1">
            {(['all', 'Pendentes', 'Prontos'] as const).map((filter) => (
              <button 
                key={filter}
                onClick={() => setDocFilter(filter)}
                className={`flex-1 py-3 py-2.5 rounded-xl text-xs font-bold transition-all ${
                  docFilter === filter 
                    ? "bg-surface-container-lowest text-primary shadow-sm" 
                    : "text-on-surface-variant hover:text-on-surface hover:bg-surface-container"
                }`}
              >
                {filter === 'all' ? 'Ver todos' : filter}
              </button>
            ))}
          </div>
        </div>

        <div className="space-y-4">
          {filteredDocs.map((doc) => (
            <GlassCard key={doc.id} className="flex items-center justify-between group hover:scale-[0.99] transition-all bg-surface-container-lowest">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-primary-container/30 flex items-center justify-center text-primary">
                {doc.type === 'file' ? <FileText size={24} /> : doc.type === 'folder' ? <Menu size={24} /> : <FileText size={24} />}
              </div>
              <div>
                <h4 className="font-bold text-on-surface">{doc.name}</h4>
                <p className="text-xs text-on-surface-variant">{doc.date}</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <span className={`text-[10px] font-bold px-3 py-1 rounded-full border ${
                doc.status === 'Pronto' ? "bg-tertiary-container/10 text-tertiary border-tertiary/20" : "bg-amber-100/10 text-amber-600 dark:text-amber-400 border-amber-500/20"
              }`}>
                {doc.status}
              </span>
              <button className={`w-10 h-10 rounded-full flex items-center justify-center transition-all ${
                doc.status === 'Pronto' ? "bg-primary text-on-primary shadow-md hover:scale-110" : "bg-surface-container text-outline-variant cursor-not-allowed"
              }`}>
                <Download size={20} />
              </button>
            </div>
          </GlassCard>
        ))}
      </div>
    </div>
    );
  };

  const ChatScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-6 max-w-3xl mx-auto">
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-outline" size={20} />
        <input 
          type="text" 
          placeholder="Buscar conversas..." 
          className="w-full bg-surface-container/50 border border-outline-variant/30 rounded-full py-4 pl-12 pr-6 outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium text-on-surface placeholder:text-on-surface-variant"
        />
      </div>

      <div className="space-y-4">
        <h3 className="text-xs font-bold uppercase tracking-widest text-on-surface-variant px-1">Conversas Recentes</h3>
        {CHATS.map((chat) => (
          <article 
            key={chat.id} 
            onClick={() => {
              setSelectedChatId(chat.id);
              setCurrentScreen('chat-detail');
            }}
            className="bg-surface-container-lowest/60 glass-panel p-5 flex items-start gap-4 hover:shadow-md transition-all cursor-pointer group"
          >
            <div className={`w-14 h-14 rounded-full flex items-center justify-center shrink-0 shadow-sm ${
              chat.type === 'bot' ? "bg-primary-container text-on-primary-container" : "bg-secondary-container text-on-secondary-container"
            }`}>
              {chat.type === 'bot' ? <Bot size={28} /> : <Users size={28} />}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex justify-between items-baseline mb-1">
                <h4 className="font-bold truncate pr-4 text-on-surface">{chat.name}</h4>
                <span className="text-[10px] text-outline whitespace-nowrap">{chat.time}</span>
              </div>
              <p className="text-sm text-on-surface-variant line-clamp-1 mb-3">{chat.lastMessage}</p>
              <div className={`inline-flex items-center px-3 py-1 rounded-full text-[10px] font-bold border ${
                chat.status === 'Active' ? "bg-primary/10 text-primary border-primary/20" : "bg-surface-variant/50 text-on-surface-variant border-outline-variant"
              }`}>
                {chat.status === 'Active' && <div className="w-1.5 h-1.5 rounded-full bg-primary mr-1.5 animate-pulse" />}
                {chat.status}
              </div>
            </div>
          </article>
        ))}
      </div>
      
      <button className="fixed bottom-28 right-5 w-16 h-16 rounded-full bg-primary text-on-primary shadow-xl flex items-center justify-center hover:scale-110 active:scale-95 transition-all z-40">
        <Plus size={32} />
      </button>
    </div>
  );

  const ManagerDashboardScreen = () => {
    // Stats for AI Intervention
    const aiStats = [
      { label: 'Resolvidos pela IA', val: '842', color: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400', icon: CheckCircle },
      { label: 'Aguardando Humano', val: '15', color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400', icon: AlertTriangle },
    ];

    return (
      <div className="pt-24 pb-28 px-5 space-y-6 max-w-7xl mx-auto">
        <header className="flex justify-between items-end">
          <div>
            <h2 className="text-3xl font-bold text-on-surface">Painel de Gestão</h2>
            <p className="text-on-surface-variant font-medium">Visão estratégica da instituição.</p>
          </div>
          <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-white shadow-md">
            <img src="https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=1974&auto=format&fit=crop" alt="Manager" className="w-full h-full object-cover" />
          </div>
        </header>

        <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {aiStats.map((stat, i) => (
            <GlassCard key={i} className="flex items-center gap-4">
              <div className={`p-4 rounded-2xl ${stat.color}`}>
                <stat.icon size={32} />
              </div>
              <div>
                <p className="text-xs font-bold uppercase tracking-widest text-on-surface-variant">{stat.label}</p>
                <p className="text-3xl font-bold text-on-surface">{stat.val}</p>
              </div>
            </GlassCard>
          ))}
        </section>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { icon: Users, label: 'Alunos Online', val: '156', color: 'primary' },
            { icon: MessageSquare, label: 'Chats Hoje', val: '234', color: 'secondary' },
            { icon: AlertTriangle, label: 'Erros IA', val: '3', color: 'error' },
            { icon: Clock, label: 'T. Médio Resposta', val: '45s', color: 'tertiary' }
          ].map((kpi, i) => (
            <GlassCard key={i} className="flex flex-col gap-3">
              <div className={`p-2.5 rounded-full bg-${kpi.color}-container w-fit text-on-${kpi.color}-container`}>
                <kpi.icon size={20} />
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-widest text-on-surface-variant mb-1">{kpi.label}</p>
                <p className={`text-2xl font-bold text-${kpi.color}`}>{kpi.val}</p>
              </div>
            </GlassCard>
          ))}
        </div>

        <section className="bg-primary/5 dark:bg-primary/10 rounded-2xl p-6 border border-primary/10 dark:border-primary/20">
          <h3 className="font-bold mb-4 flex items-center gap-2 text-on-surface">
            <Bot size={20} className="text-primary" />
            Insights de Eficiência IA
          </h3>
          <div className="space-y-3">
            <div className="flex justify-between text-sm text-on-surface">
              <span>Taxa de Resolução Automatizada</span>
              <span className="font-bold">98.2%</span>
            </div>
            <div className="w-full h-2 bg-surface-container rounded-full overflow-hidden">
              <div className="w-[98.2%] h-full bg-primary" />
            </div>
          </div>
        </section>
      </div>
    );
  };

  const ManagerChatsInterventionScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-6 max-w-3xl mx-auto">
      <header>
        <h2 className="text-3xl font-bold text-on-surface">Intervenção Humana</h2>
        <p className="text-on-surface-variant">Chats que a IA não conseguiu resolver com segurança.</p>
      </header>

      <div className="space-y-4">
        {[
          { student: 'Marcos Oliveira', ra: '20210042', issue: 'Problema crítico com boleto vencido e juros abusivos.', lastMsg: 'A IA tentou explicar o cálculo mas o aluno está exaltado.', time: '2m ago' },
          { student: 'Ana Clara Silva', ra: '20239912', issue: 'Dúvida sobre transferência externa de curso específico.', lastMsg: 'A IA não encontrou a grade curricular de destino.', time: '15m ago' }
        ].map((chat, i) => (
          <GlassCard key={i} className="hover:scale-[1.02] transition-all cursor-pointer">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center font-bold text-primary">
                  {chat.student[0]}
                </div>
                <div>
                  <h4 className="font-bold text-on-surface">{chat.student}</h4>
                  <p className="text-[10px] text-on-surface-variant font-bold">RA: {chat.ra}</p>
                </div>
              </div>
              <span className="text-[10px] font-bold bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 px-2 py-1 rounded">PENDENTE</span>
            </div>
            <div className="bg-error/5 dark:bg-error/10 p-3 rounded-lg border border-error/10 dark:border-error/20 mb-4">
              <p className="text-xs font-bold text-error uppercase tracking-wider mb-1">Motivo do Alerta</p>
              <p className="text-sm font-medium text-on-surface">{chat.issue}</p>
            </div>
            <div className="text-xs text-on-surface-variant italic mb-4">
              " {chat.lastMsg} "
            </div>
            <PillButton className="w-full">Assumir Conversa</PillButton>
          </GlassCard>
        ))}
      </div>
    </div>
  );

  const ManagerSchedulingScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-6 max-w-4xl mx-auto">
      <header className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold text-on-surface">Recursos</h2>
          <p className="text-on-surface-variant">Gestão de espaços e equipamentos.</p>
        </div>
        <PillButton onClick={() => setCurrentScreen('manager-resource-new')}><Plus size={20} /> Cadastrar</PillButton>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {[
          { name: 'Laboratório de Informática 01', type: 'Lab', status: 'Disponível', cap: '40 pessoas' },
          { name: 'Auditório Master', type: 'Auditorium', status: 'Ocupado', cap: '200 pessoas' },
          { name: 'Sala de Estudos', type: 'Room', status: 'Disponível', cap: '06 pessoas' },
          { name: 'Protetor Projetor Portátil', type: 'Equipment', status: 'Disponível', cap: 'UN: 12' }
        ].map((res, i) => (
          <GlassCard key={i} className="flex flex-col gap-4">
            <div className="flex justify-between items-start">
              <div className="p-3 bg-primary-container/20 text-primary rounded-xl">
                {res.type === 'Lab' ? <Smartphone size={24} /> : 
                 res.type === 'Auditorium' ? <Users size={24} /> : 
                 res.type === 'Room' ? <GraduationCap size={24} /> : <Settings size={24} />}
              </div>
              <span className={`text-[10px] font-bold px-2 py-1 rounded ${
                res.status === 'Disponível' ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" : "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
              }`}>{res.status}</span>
            </div>
            <div>
              <h4 className="font-bold text-on-surface">{res.name}</h4>
              <p className="text-xs text-on-surface-variant">Capacidade: {res.cap}</p>
            </div>
            <div className="flex gap-2">
              <PillButton variant="secondary" className="flex-1 text-xs py-2">Agendar Turma</PillButton>
              <PillButton variant="ghost" className="flex-1 text-xs py-2">Detalhes</PillButton>
            </div>
          </GlassCard>
        ))}
      </div>
    </div>
  );

  const ManagerInsightsScreen = () => (
    <div className="pt-24 pb-28 px-5 space-y-8 max-w-4xl mx-auto">
      <header>
        <h2 className="text-3xl font-bold text-on-surface">Insights IA</h2>
        <p className="text-on-surface-variant">Análise profunda das solicitações dos alunos.</p>
      </header>

      <section className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <GlassCard>
          <h3 className="font-bold mb-4 text-on-surface">Temas mais Recorrentes</h3>
          <div className="space-y-4">
            {[
              { label: 'Prazos de Matrícula', pct: 65, color: 'bg-primary' },
              { label: 'Acesso ao Portal', pct: 42, color: 'bg-secondary' },
              { label: 'Dúvidas Financeiras', pct: 28, color: 'bg-tertiary' },
              { label: 'Histórico Escolar', pct: 15, color: 'bg-error' }
            ].map((item, i) => (
              <div key={i} className="space-y-1">
                <div className="flex justify-between text-xs font-bold text-on-surface">
                  <span>{item.label}</span>
                  <span>{item.pct}%</span>
                </div>
                <div className="w-full h-1.5 bg-surface-container rounded-full overflow-hidden">
                  <div className={`h-full ${item.color}`} style={{ width: `${item.pct}%` }} />
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        <GlassCard className="flex flex-col">
          <h3 className="font-bold mb-4 text-on-surface">Saúde da Automação</h3>
          <div className="flex-1 flex flex-col items-center justify-center p-6 text-center">
            <div className="relative w-32 h-32 mb-4">
              <svg className="w-full h-full" viewBox="0 0 36 36">
                <circle cx="18" cy="18" r="16" fill="none" className="stroke-surface-container" strokeWidth="3" />
                <circle cx="18" cy="18" r="16" fill="none" className="stroke-primary" strokeWidth="3" strokeDasharray="90, 100" />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center font-bold text-xl text-on-surface">90%</div>
            </div>
            <p className="text-sm font-bold text-on-surface">Autossuficiência</p>
            <p className="text-xs text-on-surface-variant">9 em cada 10 problemas são resolvidos sem intervenção.</p>
          </div>
        </GlassCard>
      </section>

      <section>
        <h3 className="font-bold mb-4 text-on-surface">Principais Dores Detectadas</h3>
        <div className="space-y-3">
          {[
            { tag: 'Crítico', msg: 'Aumento de 20% em reclamações sobre o App de pagamentos na última semana.', trend: 'up', color: 'bg-error-container text-on-error-container' },
            { tag: 'Dica', msg: 'Alunos estão pedindo mais clareza no cronograma de TCC.', trend: 'stable', color: 'bg-primary-container text-on-primary-container' }
          ].map((insight, i) => (
            <GlassCard key={i} className="flex gap-4 items-center">
              <div className={`px-3 py-1 rounded-full text-[10px] font-bold ${insight.color}`}>
                {insight.tag}
              </div>
              <p className="text-sm font-medium text-on-surface">{insight.msg}</p>
            </GlassCard>
          ))}
        </div>
      </section>
    </div>
  );

  const ManagerResourceNewScreen = () => {
    return (
      <div className="pt-24 pb-28 px-5 space-y-6 max-w-2xl mx-auto">
        <header>
          <h2 className="text-3xl font-bold text-on-surface">Novo Recurso</h2>
          <p className="text-on-surface-variant">Cadastre um novo espaço ou equipamento.</p>
        </header>

        <form className="space-y-6" onSubmit={e => { e.preventDefault(); setCurrentScreen('manager-scheduling'); }}>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-bold text-on-surface mb-1">Nome do Recurso</label>
              <input type="text" className="w-full bg-surface-container-lowest border border-outline-variant/30 rounded-xl px-4 py-3 text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none focus:ring-2 focus:ring-primary/50" placeholder="Ex: Laboratório Maker" required />
            </div>

            <div>
              <label className="block text-sm font-bold text-on-surface mb-1">Tipo</label>
              <select className="w-full bg-surface-container-lowest border border-outline-variant/30 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/50">
                <option value="sala">Sala de Aula / Estudos</option>
                <option value="lab">Laboratório</option>
                <option value="auditorio">Auditório</option>
                <option value="equipamento">Equipamento</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-bold text-on-surface mb-1">Capacidade / Quantidade</label>
              <input type="text" className="w-full bg-surface-container-lowest border border-outline-variant/30 rounded-xl px-4 py-3 text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none focus:ring-2 focus:ring-primary/50" placeholder="Ex: 40 lugares" required />
            </div>
            
            <div>
              <label className="block text-sm font-bold text-on-surface mb-1">Descrição Breve</label>
              <textarea className="w-full bg-surface-container-lowest border border-outline-variant/30 rounded-xl px-4 py-3 text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none focus:ring-2 focus:ring-primary/50" rows={3} placeholder="Detalhes adicionais..."></textarea>
            </div>
          </div>

          <div className="flex gap-3">
            <PillButton variant="ghost" className="flex-1" onClick={() => setCurrentScreen('manager-scheduling')}>Cancelar</PillButton>
            <PillButton className="flex-1" onClick={() => setCurrentScreen('manager-scheduling')}>Salvar</PillButton>
          </div>
        </form>
      </div>
    );
  };

  const ChatDetailScreen = () => {
    const chat = CHATS.find(c => c.id === selectedChatId);
    const messages = selectedChatId ? MOCK_MESSAGES[selectedChatId] || [] : [];
    const [inputValue, setInputValue] = useState('');

    if (!chat) return null;

    return (
      <div className="pt-24 pb-32 px-5 flex flex-col min-h-screen max-w-3xl mx-auto">
        <div className="flex-1 space-y-6 mb-8">
          {messages.map((msg: any) => (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              key={msg.id} 
              className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div className={`max-w-[85%] p-4 rounded-2xl shadow-sm ${
                msg.sender === 'user' 
                  ? 'bg-primary text-on-primary rounded-tr-none' 
                  : 'bg-surface-container-highest text-on-surface rounded-tl-none'
              }`}>
                <p className="text-sm font-medium leading-relaxed">{msg.text}</p>
                <div className={`flex items-center gap-1 mt-2 opacity-60 ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <Clock size={10} />
                  <span className="text-[10px] font-bold uppercase">{msg.time}</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        <div className="fixed bottom-6 left-5 right-5 max-w-3xl mx-auto z-50">
          <div className="glass-panel p-2 rounded-2xl soft-shadow flex items-center gap-2">
            <input 
              type="text" 
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder="Digite sua resposta..."
              className="flex-1 bg-transparent border-none outline-none px-4 py-3 font-medium text-sm text-on-surface placeholder:text-on-surface-variant/50"
              onKeyPress={(e) => e.key === 'Enter' && setInputValue('')}
            />
            <button 
              onClick={() => setInputValue('')}
              className="w-12 h-12 rounded-xl bg-primary text-on-primary flex items-center justify-center shadow-md active:scale-95 transition-all"
            >
              <ArrowRight size={20} />
            </button>
          </div>
        </div>
      </div>
    );
  };

  const DocumentRequestScreen = () => {
    const [selectedDoc, setSelectedDoc] = useState<string | null>(null);
    const [isSubmitting, setIsSubmitting] = useState(false);

    const handleSubmit = () => {
      setIsSubmitting(true);
      setTimeout(() => {
        setIsSubmitting(false);
        setCurrentScreen('documents');
      }, 1500);
    };

    return (
      <div className="pt-24 pb-28 px-5 space-y-6 max-w-2xl mx-auto">
        <div>
          <h2 className="text-3xl font-bold text-on-surface">Solicitar Documento</h2>
          <p className="text-on-surface-variant font-medium">Selecione o documento desejado abaixo.</p>
        </div>

        <div className="space-y-3">
          {REQUESTABLE_DOCUMENTS.map((doc: any) => (
            <button 
              key={doc.id}
              onClick={() => setSelectedDoc(doc.id)}
              className={`w-full p-5 rounded-2xl border transition-all text-left flex items-center justify-between group ${
                selectedDoc === doc.id 
                  ? "bg-primary/10 border-primary shadow-sm" 
                  : "bg-surface-container-lowest border-outline-variant/30 hover:border-primary/50"
              }`}
            >
              <div className="flex items-center gap-4">
                <div className={`p-3 rounded-xl transition-colors ${selectedDoc === doc.id ? "bg-primary text-on-primary" : "bg-surface-container text-on-surface-variant group-hover:bg-primary/20"}`}>
                  <FileText size={20} />
                </div>
                <div>
                  <h4 className="font-bold text-on-surface">{doc.name}</h4>
                  <p className="text-xs text-on-surface-variant">{doc.cost}</p>
                </div>
              </div>
              <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all ${
                selectedDoc === doc.id ? "bg-primary border-primary text-on-primary scale-110" : "border-outline-variant"
              }`}>
                {selectedDoc === doc.id && <CheckCircle size={14} />}
              </div>
            </button>
          ))}
        </div>

        <div className="mt-8 space-y-4">
          <div className="p-4 rounded-xl bg-surface-container-low text-xs text-on-surface-variant flex gap-3 border border-outline-variant/20">
            <AlertTriangle className="text-amber-500 shrink-0" size={16} />
            <p>O prazo para emissão de documentos digitais é de até 24h. Documentos físicos podem levar até 5 dias úteis.</p>
          </div>
          <PillButton 
            className="w-full py-4 text-sm h-14" 
            disabled={!selectedDoc || isSubmitting}
            onClick={handleSubmit}
          >
            {isSubmitting ? (
              <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1 }}>
                <Settings size={20} />
              </motion.div>
            ) : "Confirmar Solicitação"}
          </PillButton>
        </div>
      </div>
    );
  };

  const isLoginScreen = currentScreen === 'login' || currentScreen === 'verify-code' || currentScreen === 'manager-login' || currentScreen === 'manager-verify-code';

  return (
    <div className={`min-h-screen transition-colors duration-300 ${isDarkMode ? 'dark bg-[#0f1114]' : 'bg-surface'}`}>
      <div className={isDarkMode ? 'dark' : ''}>
        {!isLoginScreen && (
          <TopAppBar 
            title={
              currentScreen === 'manager' ? 'Painel Gestor' : 
              currentScreen === 'manager-chats' ? 'Intervenção' :
              currentScreen === 'manager-scheduling' ? 'Recursos' :
              currentScreen === 'manager-resource-new' ? 'Novo Recurso' :
              currentScreen === 'manager-insights' ? 'Insights IA' :
              currentScreen === 'home' ? 'Alpha Connect' :
              currentScreen === 'notifications' ? 'Notificações' :
              currentScreen === 'documents' ? 'Documentos' :
              currentScreen === 'document-request' ? 'Nova Solicitação' :
              currentScreen === 'chat' ? 'Conversas' :
              currentScreen === 'chat-detail' ? (CHATS.find(c => c.id === selectedChatId)?.name || 'Conversa') :
              currentScreen === 'support' ? 'Suporte' : 'Alpha Connect'
            } 
            showBack={currentScreen !== 'home' && currentScreen !== 'manager' && !isLoginScreen}
          />
        )}
        
        <main className="max-w-4xl mx-auto min-h-screen">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentScreen}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.25, ease: 'easeInOut' }}
            >
              {currentScreen === 'login' && <LoginScreen />}
              {currentScreen === 'verify-code' && <VerifyCodeScreen />}
              {currentScreen === 'manager-login' && <ManagerLoginScreen />}
              {currentScreen === 'manager-verify-code' && <VerifyCodeScreen isManager={true} />}
              {currentScreen === 'home' && <StudentHomeScreen />}
              {currentScreen === 'support' && <SupportScreen />}
              {currentScreen === 'notifications' && <NotificationsScreen />}
              {currentScreen === 'documents' && <DocumentsScreen />}
              {currentScreen === 'document-request' && <DocumentRequestScreen />}
              {currentScreen === 'chat' && <ChatScreen />}
              {currentScreen === 'chat-detail' && <ChatDetailScreen />}
              {currentScreen === 'manager' && <ManagerDashboardScreen />}
              {currentScreen === 'manager-chats' && <ManagerChatsInterventionScreen />}
              {currentScreen === 'manager-scheduling' && <ManagerSchedulingScreen />}
              {currentScreen === 'manager-insights' && <ManagerInsightsScreen />}
              {currentScreen === 'manager-resource-new' && <ManagerResourceNewScreen />}
            </motion.div>
          </AnimatePresence>
        </main>

        {!isLoginScreen && <BottomNavBar />}
      </div>
    </div>
  );
}
