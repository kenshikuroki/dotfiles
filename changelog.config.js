module.exports = {
  disableEmoji: false,
  format: "{emoji}{type}: {subject}",
  maxMessageLength: 50,
  minMessageLength: 5,
  questions: [
    "type",
    "subject",
    "body",
    //"breaking",
    //"issues",
  ],
  messages: {
    type: "Prefix:",
    subject: "Abstract:\n",
    body: "Details (optional):\n",
    //breaking: "Breaking changes (optional):\n",
    //issues: "Related issues (optional), e.g. #123:",
  },
  list: [
    "feat",
    "fix",
    "perf",
    "refactor",
    "style",
    "chore",
    "docs",
    "test",
  ],
  types: {
    feat: {
      description: "New feature",
      emoji: "🎸",
      value: "feat",
    },
    fix: {
      description: "Bug fix",
      emoji: "🐛",
      value: "fix",
    },
    perf: {
      description: "Performance improvement",
      emoji: "⚡️",
      value: "perf",
    },
    refactor: {
      description: "Change that neither fixes bug nor adds feature",
      emoji: "💡",
      value: "refactor",
    },
    style: {
      description: "Change that do not affect the meaning of code (white-space, formatting, etc)",
      emoji: "💄",
      value: "style",
    },
    chore: {
      description: "Change to the build process or auxiliary tools and libraries",
      emoji: "🤖",
      value: "chore",
    },
    docs: {
      description: "Documentation change",
      emoji: "✏️",
      value: "docs",
    },
    test: {
      description: "Adding or correcting test",
      emoji: "💍",
      value: "test",
    },
  },
};
