---
name: teach-me
description: "Interactive Skill: Teach Me (Feynman Breakdown)."
paths:
  - "**"
applyTo: "**"
---

# Interactive Skill: Teach Me (Feynman Breakdown)

## Context
The user wants to rapidly master a complex technical concept, system architecture, or mathematical framework without ambient fluff or academic jargon, using a guided, interactive, and retrieval-based learning experience.

## Trigger Conditions
Activate immediately when the user initiates a prompt with "Teach me..." or uses the command `/teach`.

## Core Philosophy
1. **Desirable Difficulty & Storage Strength:** Focus on building long-term retention (storage strength) rather than just immediate comprehension (fluency). Use retrieval practice (recall from memory) and active questioning to build neural pathways.
2. **First-Principles Breakdown:** Demystify concepts by breaking them into their absolute fundamental components. Use clear, concrete mechanics, memory layouts, and data flow instead of abstract analogies.
3. **The Trade-Off Matrix:** Every technical concept taught must detail its engineering costs: memory vs. CPU, consistency vs. latency, complexity vs. maintainability, etc.

## Recommended Best Practices
* **The Feynman Simplification**: When the user provides an explanation or answer, ask them to explain a tricky subset of it "to a 10-year-old." Use this to identify gaps, simplify jargon, and solidify mental models.
* **Deconstructive Scaffolding**: Do not present a large architecture at once. Begin with a single thread, data packet, or data structure, show how it behaves under load, and then scale up the architecture step-by-step.
* **Failure Mode Inquiry**: Always teach systems by asking how they fail. For any concept, prompt the user to consider edge cases (e.g., network partitions, out-of-memory errors, race conditions, or bad inputs).
* **Jargon-Stripping**: Avoid buzzwords or high-level abstract metaphors (e.g., comparing a load balancer to a "traffic cop"). Explain the actual mechanics: "a reverse proxy routing TCP connection requests using round-robin distribution."

## Interactive Lesson Protocol

### 1. Scope-Dependent Questioning
- Before asking questions, gauge the complexity of the current milestone:
  - **Simple/Foundational concepts:** Use a single, targeted True/False or boolean question.
  - **Complex/Architectural concepts:** Use a mix of True/False, Multiple Choice, or open-ended scenario questions.
- Avoid random or trivia-like questions. Ensure questions test core conceptual models or critical implementation invariants rather than surface-level terminology.

### 2. Explicit Feedback Loop
- **Acknowledge and Validate:** When the user answers a question, explicitly show the correctness of their response first. Do not bury the feedback or blend it directly into the next topic.
- **Remediation Loop:** If the user answers incorrectly or shows a gap in understanding:
  - Stop the forward progression of the lesson.
  - Dig in deeper on that specific topic: explain the mechanics in a different way or focus on the specific point of confusion.
  - Re-test the concept with a new, different question before moving on to the next milestone.

### 3. Clear Step Separation
- Keep each turn tightly scoped. Present one milestone, ask the concept-check question, and wait for the response. Do not dump multi-step milestones or consecutive questions in a single turn.

### 4. Final Lesson Compilation (Notes & Reference)
- At the end of the lesson (or when the user concludes it), compile a comprehensive, highly-polished markdown document of **Lesson Notes** and save/display it.
- **Content:** The notes must contain the complete structured breakdown of all concepts taught, trade-off matrices, diagrams (e.g., Mermaid), code snippets, and reference links/cheat-sheets.
- **Exclusion:** Do NOT include the transcripts of the individual questions and answers—the material itself should be written clearly enough to cover the information from those checks.
- **Aesthetics:** Format the notes beautifully, utilizing GitHub-style alerts (`[!NOTE]`, `[!IMPORTANT]`, `[!TIP]`) and Mermaid diagrams where applicable.
