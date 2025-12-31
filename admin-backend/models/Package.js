import mongoose from 'mongoose';

const packageSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  nameKZ: {
    type: String,
  },
  nameRU: {
    type: String,
  },
  iconColor: {
    type: String,
    default: '#4CAF50',
  },
  price: {
    type: Number,
    required: true,
    default: 1000,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  files: {
    kz: {
      fileUrl: String,
      fileName: String,
      fileSize: Number,
      uploadedAt: Date,
    },
    ru: {
      fileUrl: String,
      fileName: String,
      fileSize: Number,
      uploadedAt: Date,
    },
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

packageSchema.pre('save', function (next) {
  this.updatedAt = Date.now();
  next();
});

export default mongoose.model('Package', packageSchema);

