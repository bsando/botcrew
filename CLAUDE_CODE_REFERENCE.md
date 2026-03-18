# Botcrew - Web Application Reference

A React + TypeScript web app for managing Claude Code multi-agent sessions. Features interactive blob sprite animations, agent details, and activity tracking.

---

## Project Structure

```
src/
├── app/
│   ├── App.tsx                      # Main application
│   ├── types.ts                     # TypeScript interfaces
│   └── components/
│       ├── MacFrame.tsx             # Mac window wrapper
│       ├── Sidebar.tsx              # Project list sidebar
│       ├── TabBar.tsx               # Agent tabs
│       ├── OfficePanel.tsx          # Canvas with blob sprites
│       ├── ActivityFeed.tsx         # Activity list
│       ├── AgentDetailsModal.tsx    # Agent detail modal
│       └── SpriteDesigns.tsx        # Pixel art sprite data
```

---

## File: `/src/app/types.ts`

```typescript
export interface Project {
  id: string;
  name: string;
  isActive: boolean;
}

export interface Tab {
  id: string;
  name: string;
  type: 'root' | 'sub';
  parentId?: string;
  isActive: boolean;
}

export interface Agent {
  id: string;
  name: string;
  status: 'typing' | 'reading' | 'waiting';
  color: string;
  role: 'root' | 'sub';
}

export interface ActivityItem {
  id: string;
  agentId: string;
  agentName: string;
  action: 'read' | 'write';
  file: string;
  timestamp: number;
}
```

---

## File: `/src/app/App.tsx`

```typescript
import { useState } from 'react';
import { MacFrame } from './components/MacFrame';
import { Sidebar } from './components/Sidebar';
import { TabBar } from './components/TabBar';
import { ActivityFeed } from './components/ActivityFeed';
import { OfficePanel } from './components/OfficePanel';
import { AgentDetailsModal } from './components/AgentDetailsModal';
import type { Project, Tab, ActivityItem, Agent } from './types';

const MOCK_PROJECTS: Project[] = [
  { id: '1', name: 'Website Redesign', isActive: true },
  { id: '2', name: 'API Integration', isActive: false },
  { id: '3', name: 'Database Migration', isActive: false },
];

const MOCK_TABS: Tab[] = [
  { id: '1', name: 'Orchestrator', type: 'root', isActive: true },
  { id: '2', name: 'Frontend Dev', type: 'sub', parentId: '1', isActive: false },
  { id: '3', name: 'Backend Dev', type: 'sub', parentId: '1', isActive: false },
  { id: '4', name: 'Database Expert', type: 'sub', parentId: '1', isActive: false },
];

const MOCK_AGENTS: Agent[] = [
  { id: '1', name: 'Orchestrator', status: 'typing', color: '#a78bfa', role: 'root' },
  { id: '2', name: 'Frontend Dev', status: 'reading', color: '#60a5fa', role: 'sub' },
  { id: '3', name: 'Backend Dev', status: 'typing', color: '#34d399', role: 'sub' },
  { id: '4', name: 'Database Expert', status: 'waiting', color: '#fbbf24', role: 'sub' },
  { id: '5', name: 'Testing Agent', status: 'typing', color: '#fb923c', role: 'sub' },
  { id: '6', name: 'Code Reviewer', status: 'reading', color: '#f87171', role: 'sub' },
  { id: '7', name: 'Documentation', status: 'waiting', color: '#f472b6', role: 'sub' },
];

const MOCK_ACTIVITIES: ActivityItem[] = [
  { id: '1', agentId: '1', agentName: 'Orchestrator', action: 'read', file: 'src/components/Header.tsx', timestamp: Date.now() - 1000 },
  { id: '2', agentId: '2', agentName: 'Frontend Dev', action: 'write', file: 'src/styles/theme.css', timestamp: Date.now() - 2000 },
  { id: '3', agentId: '3', agentName: 'Backend Dev', action: 'read', file: 'api/routes/users.ts', timestamp: Date.now() - 3000 },
  { id: '4', agentId: '1', agentName: 'Orchestrator', action: 'write', file: 'README.md', timestamp: Date.now() - 4000 },
  { id: '5', agentId: '5', agentName: 'Testing Agent', action: 'write', file: 'tests/integration.test.ts', timestamp: Date.now() - 5000 },
];

function App() {
  const [selectedProject, setSelectedProject] = useState<string>(MOCK_PROJECTS[0].id);
  const [selectedTab, setSelectedTab] = useState<string>(MOCK_TABS[0].id);
  const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
  const [highlightedActivity, setHighlightedActivity] = useState<string | null>(null);

  const selectedAgentData = selectedAgent ? MOCK_AGENTS.find(a => a.id === selectedAgent) || null : null;

  return (
    <div className="min-h-screen bg-[#1a1c2c] flex items-center justify-center p-8">
      <MacFrame title="Botcrew - Website Redesign">
        <div className="flex h-full bg-[#0f1419]">
          {/* Sidebar */}
          <Sidebar
            projects={MOCK_PROJECTS}
            selectedProject={selectedProject}
            onSelectProject={setSelectedProject}
          />

          {/* Main Content */}
          <div className="flex-1 flex flex-col">
            {/* Tab Bar */}
            <TabBar
              tabs={MOCK_TABS}
              selectedTab={selectedTab}
              onSelectTab={setSelectedTab}
            />

            {/* Split View: Office Panel + Activity Feed */}
            <div className="flex-1 flex flex-col min-h-0">
              <OfficePanel
                agents={MOCK_AGENTS}
                selectedAgent={selectedAgent}
                onSelectAgent={setSelectedAgent}
              />
              <div className="flex-1 flex min-h-0">
                <div className="flex-1"></div>
                <ActivityFeed
                  activities={MOCK_ACTIVITIES}
                  agents={MOCK_AGENTS}
                  highlightedActivity={highlightedActivity}
                  onActivityClick={setHighlightedActivity}
                />
              </div>
            </div>
          </div>
        </div>
      </MacFrame>

      {/* Agent Details Modal */}
      <AgentDetailsModal
        agent={selectedAgentData}
        activities={MOCK_ACTIVITIES}
        onClose={() => setSelectedAgent(null)}
      />
    </div>
  );
}

export default App;
```

---

## File: `/src/app/components/MacFrame.tsx`

```typescript
interface MacFrameProps {
  title: string;
  children: React.ReactNode;
}

export function MacFrame({ title, children }: MacFrameProps) {
  return (
    <div className="w-[1000px] h-[640px] bg-[#1e1e2e] rounded-lg shadow-2xl overflow-hidden flex flex-col">
      {/* Title Bar */}
      <div className="h-[32px] bg-[#2a2a3e] flex items-center px-3 gap-2 flex-shrink-0">
        <div className="flex gap-1.5">
          <div className="w-3 h-3 rounded-full bg-[#ff5f57]"></div>
          <div className="w-3 h-3 rounded-full bg-[#febc2e]"></div>
          <div className="w-3 h-3 rounded-full bg-[#28c840]"></div>
        </div>
        <div className="flex-1 text-center text-xs text-white/50 font-medium -ml-14">
          {title}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden">
        {children}
      </div>
    </div>
  );
}
```

---

## File: `/src/app/components/Sidebar.tsx`

```typescript
import type { Project } from '../types';

interface SidebarProps {
  projects: Project[];
  selectedProject: string;
  onSelectProject: (id: string) => void;
}

export function Sidebar({ projects, selectedProject, onSelectProject }: SidebarProps) {
  return (
    <div className="w-[180px] bg-[#1a1d28] border-r border-white/[0.06] flex flex-col flex-shrink-0">
      <div className="h-[28px] bg-[#0F1020] flex items-center px-3 border-b border-white/[0.06] flex-shrink-0">
        <div className="text-[10px] text-white/30 font-mono tracking-wider">PROJECTS</div>
      </div>
      <div className="flex-1 overflow-auto p-2">
        {projects.map((project) => (
          <button
            key={project.id}
            onClick={() => onSelectProject(project.id)}
            className={`
              w-full text-left px-3 py-2 rounded text-xs mb-1
              transition-colors
              ${selectedProject === project.id
                ? 'bg-[#2a5a8a] text-white/90'
                : 'text-white/60 hover:bg-white/[0.05] hover:text-white/80'
              }
            `}
          >
            {project.name}
          </button>
        ))}
      </div>
    </div>
  );
}
```

---

## File: `/src/app/components/TabBar.tsx`

```typescript
import type { Tab } from '../types';

interface TabBarProps {
  tabs: Tab[];
  selectedTab: string;
  onSelectTab: (id: string) => void;
}

export function TabBar({ tabs, selectedTab, onSelectTab }: TabBarProps) {
  return (
    <div className="h-[32px] bg-[#1a1d28] border-b border-white/[0.06] flex items-center px-2 gap-1 flex-shrink-0">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onSelectTab(tab.id)}
          className={`
            px-3 py-1 rounded text-[11px] font-medium transition-colors
            ${tab.type === 'sub' ? 'ml-4' : ''}
            ${selectedTab === tab.id
              ? 'bg-[#2a5a8a] text-white/90'
              : 'text-white/50 hover:text-white/70 hover:bg-white/[0.05]'
            }
          `}
        >
          {tab.name}
        </button>
      ))}
    </div>
  );
}
```

---

## File: `/src/app/components/ActivityFeed.tsx`

```typescript
import type { ActivityItem, Agent } from '../types';

interface ActivityFeedProps {
  activities: ActivityItem[];
  agents: Agent[];
  highlightedActivity: string | null;
  onActivityClick: (activityId: string) => void;
}

export function ActivityFeed({ activities, agents, highlightedActivity, onActivityClick }: ActivityFeedProps) {
  const getAgentColor = (agentId: string) => {
    const agent = agents.find(a => a.id === agentId);
    return agent?.color || '#888';
  };

  const getActionIcon = (action: 'read' | 'write') => {
    if (action === 'read') {
      return { bg: 'bg-[#1a3a4a]', text: 'text-[#60a5fa]', symbol: '📖' };
    } else {
      return { bg: 'bg-[#1a3a2a]', text: 'text-[#34d399]', symbol: '✍️' };
    }
  };

  const formatTime = (timestamp: number) => {
    const seconds = Math.floor((Date.now() - timestamp) / 1000);
    if (seconds < 60) return `${seconds}s ago`;
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    return `${hours}h ago`;
  };

  return (
    <div className="w-80 bg-[#1a1d28] border-l border-white/[0.06] flex flex-col">
      {/* Header */}
      <div className="h-[28px] bg-[#0F1020] flex items-center px-4 border-b border-white/[0.06] flex-shrink-0">
        <div className="text-[10px] text-white/30 font-mono tracking-wider">
          ACTIVITY FEED
        </div>
        <div className="ml-auto text-[10px] text-white/20 font-mono">
          {activities.length} events
        </div>
      </div>

      {/* Activity List */}
      <div className="flex-1 overflow-auto">
        {activities.map((activity) => {
          const icon = getActionIcon(activity.action);
          const agentColor = getAgentColor(activity.agentId);
          const isHighlighted = activity.id === highlightedActivity;

          return (
            <div
              key={activity.id}
              onClick={() => onActivityClick(activity.id)}
              className={`
                px-4 py-3 border-b border-white/[0.04] cursor-pointer
                transition-colors hover:bg-white/[0.03]
                ${isHighlighted ? 'bg-white/[0.06] border-l-2 border-l-blue-400' : ''}
              `}
            >
              {/* Agent Name & Time */}
              <div className="flex items-center gap-2 mb-1.5">
                <div 
                  className="w-2 h-2 rounded-full flex-shrink-0" 
                  style={{ backgroundColor: agentColor }}
                ></div>
                <div className="text-[11px] font-medium text-white/70">
                  {activity.agentName}
                </div>
                <div className="text-[9px] text-white/25 ml-auto">
                  {formatTime(activity.timestamp)}
                </div>
              </div>

              {/* Action & File */}
              <div className="flex items-start gap-2">
                <div className={`
                  w-6 h-6 rounded ${icon.bg} flex items-center justify-center
                  text-xs flex-shrink-0
                `}>
                  {icon.symbol}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[10px] text-white/50 mb-0.5">
                    {activity.action === 'read' ? 'Reading' : 'Writing'}
                  </div>
                  <div className="text-[11px] text-white/80 font-mono truncate">
                    {activity.file}
                  </div>
                </div>
              </div>
            </div>
          );
        })}

        {activities.length === 0 && (
          <div className="flex items-center justify-center h-32 text-white/20 text-sm">
            No activity yet
          </div>
        )}
      </div>
    </div>
  );
}
```

---

## File: `/src/app/components/AgentDetailsModal.tsx`

```typescript
import type { Agent, ActivityItem } from '../types';

interface AgentDetailsModalProps {
  agent: Agent | null;
  activities: ActivityItem[];
  onClose: () => void;
}

export function AgentDetailsModal({ agent, activities, onClose }: AgentDetailsModalProps) {
  if (!agent) return null;

  const agentActivities = activities.filter(a => a.agentId === agent.id);
  
  const stats = {
    reads: agentActivities.filter(a => a.action === 'read').length,
    writes: agentActivities.filter(a => a.action === 'write').length,
    total: agentActivities.length,
  };

  const formatTime = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  };

  return (
    <div 
      className="fixed inset-0 bg-black/60 flex items-center justify-center z-50"
      onClick={onClose}
    >
      <div 
        className="bg-[#1a1d28] rounded-lg border border-white/[0.1] w-[500px] max-h-[600px] flex flex-col shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-white/[0.08] flex items-center gap-3">
          <div 
            className="w-10 h-10 rounded-lg flex items-center justify-center text-2xl"
            style={{ backgroundColor: agent.color + '20', color: agent.color }}
          >
            🫧
          </div>
          <div className="flex-1">
            <div className="text-base font-semibold text-white/90">{agent.name}</div>
            <div className="text-xs text-white/40 capitalize">{agent.role} Agent</div>
          </div>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded hover:bg-white/[0.08] flex items-center justify-center text-white/40 hover:text-white/70 transition-colors"
          >
            ✕
          </button>
        </div>

        {/* Status */}
        <div className="px-5 py-3 bg-[#0F1020] border-b border-white/[0.06]">
          <div className="flex items-center gap-2">
            <div className="text-[10px] text-white/40 uppercase tracking-wider">Status</div>
            <div className={`
              px-2.5 py-1 rounded-full text-[11px] font-medium
              ${agent.status === 'typing' ? 'bg-green-500/20 text-green-400' : ''}
              ${agent.status === 'reading' ? 'bg-blue-500/20 text-blue-400' : ''}
              ${agent.status === 'waiting' ? 'bg-yellow-500/20 text-yellow-400' : ''}
            `}>
              {agent.status === 'typing' && '✍️ Writing'}
              {agent.status === 'reading' && '📖 Reading'}
              {agent.status === 'waiting' && '⏳ Waiting'}
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="px-5 py-4 border-b border-white/[0.06] grid grid-cols-3 gap-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-white/90">{stats.total}</div>
            <div className="text-[10px] text-white/40 uppercase tracking-wider mt-1">Total Actions</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-400">{stats.reads}</div>
            <div className="text-[10px] text-white/40 uppercase tracking-wider mt-1">Reads</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-400">{stats.writes}</div>
            <div className="text-[10px] text-white/40 uppercase tracking-wider mt-1">Writes</div>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="flex-1 overflow-auto">
          <div className="px-5 py-3 border-b border-white/[0.06] bg-[#0F1020]">
            <div className="text-[11px] text-white/50 uppercase tracking-wider font-semibold">
              Recent Activity ({agentActivities.length})
            </div>
          </div>
          <div className="divide-y divide-white/[0.04]">
            {agentActivities.length === 0 ? (
              <div className="px-5 py-8 text-center text-white/30 text-sm">
                No activity recorded yet
              </div>
            ) : (
              agentActivities.map((activity) => (
                <div key={activity.id} className="px-5 py-3 hover:bg-white/[0.02]">
                  <div className="flex items-start gap-3">
                    <div className={`
                      w-8 h-8 rounded flex items-center justify-center text-sm flex-shrink-0
                      ${activity.action === 'read' ? 'bg-blue-500/10 text-blue-400' : 'bg-green-500/10 text-green-400'}
                    `}>
                      {activity.action === 'read' ? '📖' : '✍️'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-xs text-white/70 font-mono truncate">
                        {activity.file}
                      </div>
                      <div className="text-[10px] text-white/40 mt-1">
                        {activity.action === 'read' ? 'Read' : 'Wrote'} · {formatTime(activity.timestamp)}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## File: `/src/app/components/OfficePanel.tsx`

```typescript
import { useEffect, useRef, useState } from 'react';
import type { Agent } from '../types';
import { SPRITE_DESIGNS } from './SpriteDesigns';

const BLOB = SPRITE_DESIGNS.blob;

interface OfficePanelProps {
  agents: Agent[];
  selectedAgent: string | null;
  onSelectAgent: (agentId: string) => void;
}

export function OfficePanel({ agents, selectedAgent, onSelectAgent }: OfficePanelProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [time, setTime] = useState(0);
  const [hoveredAgent, setHoveredAgent] = useState<string | null>(null);
  const agentPositionsRef = useRef<Map<string, { x: number; y: number; width: number; height: number }>>(new Map());

  useEffect(() => {
    const interval = setInterval(() => {
      setTime((t) => t + 0.04);
    }, 40);
    return () => clearInterval(interval);
  }, []);

  const handleCanvasClick = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    // Check if click is within any agent's bounds
    for (const [agentId, bounds] of agentPositionsRef.current.entries()) {
      if (
        x >= bounds.x &&
        x <= bounds.x + bounds.width &&
        y >= bounds.y &&
        y <= bounds.y + bounds.height
      ) {
        onSelectAgent(agentId);
        return;
      }
    }
  };

  const handleCanvasMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    // Check if hovering over any agent
    let foundAgent = false;
    for (const [agentId, bounds] of agentPositionsRef.current.entries()) {
      if (
        x >= bounds.x &&
        x <= bounds.x + bounds.width &&
        y >= bounds.y &&
        y <= bounds.y + bounds.height
      ) {
        setHoveredAgent(agentId);
        foundAgent = true;
        return;
      }
    }

    if (!foundAgent) {
      setHoveredAgent(null);
    }
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const parent = canvas.parentElement;
    if (!parent) return;

    const W = parent.clientWidth;
    const H = parent.clientHeight;
    
    canvas.width = W;
    canvas.height = H;

    // Clear positions
    agentPositionsRef.current.clear();

    const drawSprite = (cx: number, cy: number, anim: string, body: string, shirt: string, bobY: number, S: number) => {
      const grid = anim === 'error' ? BLOB.ERROR : anim === 'shrug' ? BLOB.SHRUG : anim === 'type' ? BLOB.TYPE : BLOB.BODY;
      const pal: Record<number, string> = { 
        1: body, 
        2: '#1a1c2c', 
        3: '#ffb060', 
        4: shirt, 
        5: '#ff8080', 
        6: '#ff2020',
        7: body,
      };
      const ox = cx - 4 * S;
      const oy = cy - 5 * S + bobY;
      
      grid.forEach((row, r) => {
        row.forEach((v, c) => {
          if (!v || !pal[v]) return;
          ctx.fillStyle = pal[v];
          ctx.fillRect(Math.round(ox + c * S), Math.round(oy + r * S), Math.ceil(S), Math.ceil(S));
        });
      });
    };

    const drawDesk = (cx: number, cy: number, S: number) => {
      const w = Math.round(24 * S);
      const h = Math.round(5 * S);
      ctx.fillStyle = '#28206a';
      ctx.fillRect(cx - w / 2, cy, w, h);
      ctx.fillStyle = 'rgba(0,0,0,0.3)';
      ctx.fillRect(cx - w / 2, cy + h - 1, w, 1);
    };

    const bob = (anim: string, phase: number): number => {
      if (anim === 'type') return Math.round(Math.sin(time * 9 + phase) * 1.4);
      if (anim === 'shrug') return Math.round(Math.sin(time * 2 + phase) * 0.9);
      return Math.round(Math.sin(time * 1.3 + phase) * 0.55);
    };

    // Clear and draw background
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = '#191a2e';
    ctx.fillRect(0, 0, W, H);

    // Grid
    ctx.strokeStyle = 'rgba(255,255,255,0.04)';
    ctx.lineWidth = 0.5;
    for (let x = 0; x < W; x += 20) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, H);
      ctx.stroke();
    }
    for (let y = 0; y < H; y += 20) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(W, y);
      ctx.stroke();
    }

    const S = 2;
    const positions = [
      // Top row - 4 agents
      { x: 0.20, y: 0.35 },
      { x: 0.37, y: 0.35 },
      { x: 0.63, y: 0.35 },
      { x: 0.80, y: 0.35 },
      // Bottom row - 3 agents
      { x: 0.28, y: 0.70 },
      { x: 0.50, y: 0.70 },
      { x: 0.72, y: 0.70 },
    ];

    // Draw agents
    agents.forEach((agent, i) => {
      if (i >= positions.length) return;

      const pos = positions[i];
      const cx = Math.round(pos.x * W);
      const cy = Math.round(pos.y * H);
      
      const anim = agent.status === 'typing' ? 'type' : agent.status === 'waiting' ? 'shrug' : 'body';
      const bobY = bob(anim, i * 1.3);

      // Store agent position for click detection
      const spriteWidth = 16 * S;
      const spriteHeight = 24 * S;
      agentPositionsRef.current.set(agent.id, {
        x: cx - spriteWidth / 2,
        y: cy - spriteHeight / 2,
        width: spriteWidth,
        height: spriteHeight,
      });

      // Draw desk
      drawDesk(cx, cy + Math.round(8 * S), S);
      
      // Draw sprite
      drawSprite(cx, cy, anim, agent.color, agent.color, bobY, S);

      // Status dot
      const dx = cx + Math.round(8 * S);
      const dy = cy - Math.round(10 * S);
      ctx.beginPath();
      ctx.arc(dx, dy, 3, 0, Math.PI * 2);
      ctx.fillStyle = '#0d0e18';
      ctx.fill();
      ctx.beginPath();
      ctx.arc(dx, dy, 2, 0, Math.PI * 2);
      const statusColors = {
        typing: '#34d399',
        reading: '#60a5fa',
        waiting: '#fbbf24',
      };
      ctx.fillStyle = statusColors[agent.status];
      ctx.fill();

      // Selection ring
      if (agent.id === selectedAgent) {
        ctx.save();
        ctx.strokeStyle = agent.color;
        ctx.lineWidth = 2;
        ctx.globalAlpha = 0.9;
        ctx.strokeRect(
          cx - Math.round(12 * S),
          cy - Math.round(14 * S),
          Math.round(24 * S),
          Math.round(32 * S)
        );
        ctx.restore();
      }

      // Hover ring
      if (agent.id === hoveredAgent && agent.id !== selectedAgent) {
        ctx.save();
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
        ctx.lineWidth = 1;
        ctx.setLineDash([4, 4]);
        ctx.strokeRect(
          cx - Math.round(12 * S),
          cy - Math.round(14 * S),
          Math.round(24 * S),
          Math.round(32 * S)
        );
        ctx.restore();
      }

      // Label
      ctx.fillStyle = 'rgba(255,255,255,0.4)';
      ctx.font = '9px monospace';
      ctx.textAlign = 'center';
      ctx.fillText(agent.name, cx, cy + Math.round(24 * S));

      // Hover tooltip
      if (agent.id === hoveredAgent) {
        const tooltipText = `${agent.name} · ${agent.status}`;
        const tooltipWidth = ctx.measureText(tooltipText).width + 16;
        const tooltipX = cx - tooltipWidth / 2;
        const tooltipY = cy - Math.round(20 * S);

        ctx.fillStyle = 'rgba(0, 0, 0, 0.95)';
        ctx.beginPath();
        ctx.roundRect(tooltipX, tooltipY, tooltipWidth, 18, 4);
        ctx.fill();

        ctx.fillStyle = '#ffffff';
        ctx.font = '10px monospace';
        ctx.textAlign = 'center';
        ctx.fillText(tooltipText, cx, tooltipY + 12);
      }

      // Typing bubble
      if (anim === 'type') {
        const bx = cx + Math.round(10 * S);
        const by = cy - Math.round(16 * S);
        ctx.fillStyle = 'rgba(255,255,255,0.9)';
        ctx.beginPath();
        ctx.roundRect(bx, by - 8, 32, 10, 2);
        ctx.fill();
        ctx.fillStyle = '#222';
        ctx.font = '8px monospace';
        ctx.textAlign = 'left';
        ctx.fillText('writing' + '.'.repeat(1 + Math.floor(time * 2.5) % 3), bx + 4, by);
      }

      // Waiting bubble
      if (anim === 'shrug') {
        const bx = cx + Math.round(10 * S);
        const by = cy - Math.round(16 * S);
        ctx.fillStyle = 'rgba(255,200,80,0.9)';
        ctx.beginPath();
        ctx.roundRect(bx, by - 8, 28, 10, 2);
        ctx.fill();
        ctx.fillStyle = '#332200';
        ctx.font = '8px monospace';
        ctx.textAlign = 'left';
        ctx.fillText('waiting', bx + 4, by);
      }
    });
  }, [agents, selectedAgent, hoveredAgent, time]);

  return (
    <div className="h-[180px] bg-[#191A2E] flex-shrink-0 flex flex-col border-b border-white/[0.06]">
      <div className="h-[28px] bg-[#0F1020] flex items-center px-4 gap-3 border-b border-white/[0.06] flex-shrink-0">
        <div className="text-[10px] text-white/30 font-mono tracking-wider">
          OFFICE VIEW
        </div>
        <div className="flex gap-1.5 items-center">
          {agents.map((agent) => (
            <div 
              key={agent.id} 
              className="w-[6px] h-[6px] rounded-full" 
              style={{ 
                background: agent.status === 'typing' ? '#34d399' : agent.status === 'reading' ? '#60a5fa' : '#fbbf24'
              }}
            ></div>
          ))}
        </div>
        <div className="ml-auto text-[10px] text-white/20 font-mono">
          {agents.length} agents · click to inspect
        </div>
      </div>
      <div className="flex-1 relative overflow-hidden">
        <canvas 
          ref={canvasRef} 
          className="w-full h-full cursor-pointer" 
          style={{ imageRendering: 'pixelated' }}
          onClick={handleCanvasClick}
          onMouseMove={handleCanvasMove}
          onMouseLeave={() => setHoveredAgent(null)}
        />
      </div>
    </div>
  );
}
```

---

## File: `/src/app/components/SpriteDesigns.tsx`

*Note: This file contains 8 different sprite design systems. Only the blob design is currently used.*

```typescript
// Pixel art sprite data for different design styles
export const SPRITE_DESIGNS = {
  blob: {
    BODY: [
      [0,0,0,1,1,1,0,0],
      [0,0,1,1,1,1,1,0],
      [0,1,1,2,1,2,1,1],
      [0,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1],
      [1,1,3,1,1,3,1,1],
      [1,1,1,1,1,1,1,1],
      [0,1,1,1,1,1,1,0],
      [0,0,1,1,1,1,0,0],
      [0,0,0,1,1,0,0,0],
    ],
    TYPE: [
      [0,0,0,1,1,1,0,0],
      [0,0,1,1,1,1,1,0],
      [0,1,1,2,1,2,1,1],
      [1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1],
      [1,1,3,1,1,3,1,1],
      [1,1,1,3,3,1,1,1],
      [0,1,1,1,1,1,1,0],
      [0,0,1,1,1,1,0,0],
      [0,0,0,1,1,0,0,0],
    ],
    SHRUG: [
      [0,0,0,1,1,1,0,0],
      [0,1,1,1,1,1,1,1],
      [0,1,1,2,1,2,1,1],
      [0,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1],
      [1,1,3,1,1,3,1,1],
      [1,1,1,1,1,1,1,1],
      [0,1,1,1,1,1,1,0],
      [0,0,1,1,1,1,0,0],
      [0,0,0,1,1,0,0,0],
    ],
    ERROR: [
      [0,0,0,1,1,1,0,0],
      [0,0,1,1,1,1,1,0],
      [0,1,1,6,1,6,1,1],
      [0,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1],
      [1,1,3,3,3,3,1,1],
      [0,1,1,3,3,1,1,0],
      [0,0,1,1,1,1,0,0],
      [0,0,0,1,1,0,0,0],
    ],
  },
  
  // Other sprite designs omitted for brevity (original, cute, geometric, retro, etc.)
  // These can be added later if needed
};
```

---

## Key Features

### Interactive Elements
1. **Click agents** - Opens detail modal with stats and activity history
2. **Hover agents** - Shows tooltip with agent name and status
3. **Click activities** - Highlights the activity item
4. **Animated sprites** - Blob creatures bob and animate based on status

### Data Flow
- `App.tsx` manages all state (selected project, tab, agent, highlighted activity)
- State flows down as props to child components
- Event handlers flow up to update state in App

### Styling
- Uses Tailwind CSS with dark theme
- Custom colors: `#1a1c2c`, `#191a2e`, `#0f1419`, etc.
- Pixel art rendered on HTML5 Canvas with `imageRendering: 'pixelated'`

### Status Types
- **typing** - Green indicator, bouncing animation, "writing..." bubble
- **reading** - Blue indicator, gentle bob animation
- **waiting** - Yellow indicator, slow bob, "waiting" bubble

---

## Usage with Claude Code

Simply share this file with Claude Code and reference it as:

*"Here's the Botcrew app - a React TypeScript app for visualizing AI agents as animated blob sprites. All source code is included above. The main components are MacFrame, Sidebar, TabBar, OfficePanel (canvas-based sprite rendering), ActivityFeed, and AgentDetailsModal."*
