/**
 * Type definitions index for Fictioneer
 * Re-exports all type definitions for easier importing
 */

// Progress tracking types
export type {
	ProgressGoals,
	DailyProgress,
	ProgressStats,
	ChartDataPoint,
	ProjectWithProgress
} from './progress.js';

// Text analysis types
export type {
	HighlightType,
	HighlightSeverity,
	AnalysisHighlight,
	ReadabilityScores,
	SentenceStats,
	SentenceStarterStats,
	ProseMetrics,
	WordRepetition,
	PassiveVoiceMatch,
	AdverbMatch,
	FilterWordMatch,
	WeakVerbMatch,
	SceneAnalysisResult,
	AnalysisIssue,
	AnalysisConfig,
	// AI Analysis types
	ShowTellRequest,
	ShowTellResponse,
	TellingPassage,
	POVRequest,
	POVResponse,
	POVSlip,
	ToneRequest,
	ToneResponse,
	EmotionalArcPoint,
	ConsistencyRequest,
	ConsistencyResponse,
	CharacterInconsistency,
	TimelineIssue,
	FactualContradiction
} from './analysis.js';

export { DEFAULT_ANALYSIS_CONFIG } from './analysis.js';
