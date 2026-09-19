import { SafetyLevel } from "./domain.js";

// 보수적인 MVP 차단 목록이다. 운영 환경에서는 최신 공식 위기지원 정보와
// 별도의 안전 분류기를 서버에서 주입해야 한다.
const CRISIS_PATTERNS = [
  /자살|자해|죽고\s*싶|목숨을\s*끊/i,
  /suicid|self[- ]?harm|kill myself/i,
];

const DIAGNOSIS_PATTERNS = [
  /진단해|병명|우울증인지|adhd인지|정신병인지/i,
  /diagnose me|do i have (?:depression|adhd)/i,
];

export function classifySafety(text) {
  const normalized = String(text ?? "").trim();
  if (CRISIS_PATTERNS.some((pattern) => pattern.test(normalized))) {
    return {
      level: SafetyLevel.CRISIS,
      reasonCode: "CRISIS_LANGUAGE_DETECTED",
      allowMission: false,
      message: "지금은 일반 Mission보다 안전이 우선입니다. 즉시 주변의 믿을 수 있는 사람이나 지역의 긴급·전문 지원 기관에 도움을 요청해 주세요.",
    };
  }
  if (DIAGNOSIS_PATTERNS.some((pattern) => pattern.test(normalized))) {
    return {
      level: SafetyLevel.REVIEW,
      reasonCode: "DIAGNOSIS_REQUEST_DETECTED",
      allowMission: false,
      message: "채움은 정신건강이나 성격을 진단하지 않습니다. 진단이 필요하다면 자격을 갖춘 전문가와 상담해 주세요.",
    };
  }
  return { level: SafetyLevel.SAFE, reasonCode: "NO_SAFETY_SIGNAL", allowMission: true };
}
