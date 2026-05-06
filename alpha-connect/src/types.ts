/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { 
  Home, 
  MessageSquare, 
  FileText, 
  Bell, 
  Headset, 
  Menu, 
  Sun,
  LayoutDashboard,
  User,
  ArrowRight,
  Download,
  Search,
  Upload,
  Plus,
  Clock,
  CheckCircle,
  AlertCircle,
  MoreVertical,
  LogOut,
  Settings
} from 'lucide-react';

export type ScreenId = 'login' | 'verify-code' | 'manager-login' | 'manager-verify-code' | 'home' | 'support' | 'notifications' | 'documents' | 'document-request' | 'chat' | 'chat-detail' | 'manager' | 'manager-chats' | 'manager-scheduling' | 'manager-insights' | 'manager-resource-new';

export const REQUESTABLE_DOCUMENTS = [
  { id: 'req1', name: 'Histórico Escolar Atualizado', cost: 'Gratuito' },
  { id: 'req2', name: 'Declaração de Matrícula', cost: 'Gratuito' },
  { id: 'req3', name: 'Certificado de Conclusão', cost: 'R$ 25,00' },
  { id: 'req4', name: 'Plano de Ensino', cost: 'R$ 15,00' },
  { id: 'req5', name: 'Certidão de Notas e Frequência', cost: 'Gratuito' }
];

export interface Message {
  id: string;
  sender: 'user' | 'bot' | 'human';
  text: string;
  time: string;
}

export interface ManagerInsights {
  category: string;
  count: number;
  trend: 'up' | 'down' | 'stable';
}

export interface ResourceItem {
  id: string;
  name: string;
  type: 'Lab' | 'Auditorium' | 'Room' | 'Equipment';
  status: 'Available' | 'Reserved';
}

export const MANAGER_INSIGHTS: ManagerInsights[] = [
  { category: 'Prazos de Matrícula', count: 145, trend: 'up' },
  { category: 'Acesso ao Portal', count: 89, trend: 'stable' },
  { category: 'Dúvidas Financeiras', count: 67, trend: 'down' },
  { category: 'Histórico Escolar', count: 42, trend: 'stable' }
];

export const RESOURCES: ResourceItem[] = [
  { id: '1', name: 'Laboratório de Informática 01', type: 'Lab', status: 'Available' },
  { id: '2', name: 'Auditório Master', type: 'Auditorium', status: 'Reserved' },
  { id: '3', name: 'Sala de Estudos Individual', type: 'Room', status: 'Available' },
  { id: '4', name: 'Protetor Projetor Portátil', type: 'Equipment', status: 'Available' }
];
export interface Notification {
  id: string;
  category: 'Documentos' | 'Coordenação' | 'Acadêmico' | 'Sistema';
  time: string;
  title: string;
  description: string;
  isUnread: boolean;
  type: 'doc' | 'msg' | 'event' | 'system';
}

export interface Chat {
  id: string;
  name: string;
  lastMessage: string;
  time: string;
  status: 'Active' | 'Closed';
  type: 'bot' | 'human';
}

export interface DocumentItem {
  id: string;
  name: string;
  date: string;
  status: 'Pronto' | 'Processando' | 'Pendente';
  type: 'file' | 'folder' | 'assignment';
}

export const NOTIFICATIONS: Notification[] = [
  {
    id: '1',
    category: 'Documentos',
    time: 'Há 5 min',
    title: 'Seu Histórico Escolar está pronto para download',
    description: 'O documento solicitado na secretaria virtual já se encontra disponível no seu portal do aluno.',
    isUnread: true,
    type: 'doc'
  },
  {
    id: '2',
    category: 'Coordenação',
    time: 'Hoje, 09:30',
    title: 'Nova mensagem da coordenação',
    description: 'Prezado aluno, confira as atualizações sobre o cronograma de bancas de TCC para o semestre atual.',
    isUnread: true,
    type: 'msg'
  },
  {
    id: '3',
    category: 'Acadêmico',
    time: 'Ontem, 14:00',
    title: 'Lembrete: Reunião de orientação amanhã',
    description: 'Não esqueça de levar a versão impressa do seu rascunho para a reunião com seu orientador na sala 302.',
    isUnread: false,
    type: 'event'
  },
  {
    id: '4',
    category: 'Sistema',
    time: '12 Out, 08:00',
    title: 'Manutenção programada concluída',
    description: 'O sistema de envio de atividades foi atualizado com sucesso. O acesso já está normalizado.',
    isUnread: false,
    type: 'system'
  }
];

export const CHATS: Chat[] = [
  {
    id: '1',
    name: 'Academic Advisor Bot',
    lastMessage: 'Here are the documents you requested for the upcoming semester enrollment.',
    time: '10:42 AM',
    status: 'Active',
    type: 'bot'
  },
  {
    id: '2',
    name: 'Support Team - Finance',
    lastMessage: 'Your payment plan has been successfully updated. Let us know if you need anything else.',
    time: 'Yesterday',
    status: 'Closed',
    type: 'human'
  },
  {
    id: '3',
    name: 'Library Assistant Bot',
    lastMessage: "The book 'Advanced Calculus' is now available for pickup at the main desk.",
    time: 'Oct 12',
    status: 'Closed',
    type: 'bot'
  }
];

export const DOCUMENTS: DocumentItem[] = [
  {
    id: '1',
    name: 'Histórico Escolar',
    date: 'Solicitado em 12 Out 2023',
    status: 'Pronto',
    type: 'file'
  },
  {
    id: '2',
    name: 'Declaração de Matrícula',
    date: 'Solicitado em 15 Out 2023',
    status: 'Processando',
    type: 'folder'
  },
  {
    id: '3',
    name: 'Certificado de Conclusão',
    date: 'Solicitado em 01 Set 2023',
    status: 'Pronto',
    type: 'assignment'
  }
];

export const MOCK_MESSAGES: Record<string, Message[]> = {
  '1': [
    { id: '1-1', sender: 'bot', text: 'Olá! Sou o assistente acadêmico. Como posso ajudar?', time: '10:40 AM' },
    { id: '1-2', sender: 'user', text: 'Gostaria de ver os documentos para rematrícula.', time: '10:41 AM' },
    { id: '1-3', sender: 'bot', text: 'Com certeza! Aqui estão os documentos que você solicitou para a rematrícula do próximo semestre.', time: '10:42 AM' },
  ],
  '2': [
    { id: '2-1', sender: 'human', text: 'Olá Marcos, seu plano de pagamento foi atualizado.', time: 'Yesterday' },
    { id: '2-2', sender: 'user', text: 'Obrigado pelo retorno!', time: 'Yesterday' },
    { id: '2-3', sender: 'human', text: 'De nada! Estaremos à disposição.', time: 'Yesterday' },
  ],
  '3': [
    { id: '3-1', sender: 'bot', text: "O livro 'Cálculo Avançado' já está disponível para retirada no balcão principal.", time: 'Oct 12' },
  ]
};
