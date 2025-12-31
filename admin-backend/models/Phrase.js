import mongoose from 'mongoose';

const phraseSchema = new mongoose.Schema({
  language: {
    type: String,
    required: true,
    enum: ['KZ', 'RU'],
  },
  fileUrl: {
    type: String,
    required: true,
  },
  fileName: {
    type: String,
    required: true,
  },
  fileSize: {
    type: Number,
  },
  uploadedAt: {
    type: Date,
    default: Date.now,
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
  },
});

export default mongoose.model('Phrase', phraseSchema);

