import type { Assignment, CheckResult, Submission } from '../shared/api/types'
import { assignmentsSeed, candidatesSeed, createAiReviewsSeed, createResultsSeed, createSubmissionsSeed, users } from './seed'

export const db = {
  users,
  assignments: [...assignmentsSeed],
  candidates: [...candidatesSeed],
  submissions: createSubmissionsSeed(),
  results: [] as CheckResult[],
  aiReviews: new Map(),
}

db.results = createResultsSeed(db.submissions)
db.aiReviews = createAiReviewsSeed(db.submissions)

export function findSubmission(id: string) {
  return db.submissions.find((submission) => submission.id === id)
}

export function upsertAssignment(assignment: Assignment) {
  const index = db.assignments.findIndex((item) => item.id === assignment.id)
  if (index >= 0) {
    db.assignments[index] = assignment
  } else {
    db.assignments.unshift(assignment)
  }
}

export function replaceSubmission(submission: Submission) {
  const index = db.submissions.findIndex((item) => item.id === submission.id)
  if (index >= 0) {
    db.submissions[index] = submission
  }
}
