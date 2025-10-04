const express = require("express")
const multer = require("multer")
const cors = require("cors")
const path = require("path")
const fs = require("fs")

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(cors())
app.use(express.json())
app.use(express.static("public"))
app.use("/uploads", express.static("uploads"))

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "uploads")
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true })
}

// Metadata file path
const metadataFile = path.join(__dirname, "images.json")

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/")
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9)
    const ext = path.extname(file.originalname)
    cb(null, file.fieldname + "-" + uniqueSuffix + ext)
  },
})

// File filter to accept only images
const fileFilter = (req, file, cb) => {
  const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/gif"]
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true)
  } else {
    cb(new Error("Only image files (JPEG, PNG, GIF) are allowed"), false)
  }
}

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: fileFilter,
})

// Helper function to read metadata
function readMetadata() {
  try {
    if (fs.existsSync(metadataFile)) {
      const data = fs.readFileSync(metadataFile, "utf8")
      return JSON.parse(data)
    }
  } catch (error) {
    console.error("Error reading metadata:", error)
  }
  return []
}

// Helper function to write metadata
function writeMetadata(metadata) {
  try {
    fs.writeFileSync(metadataFile, JSON.stringify(metadata, null, 2))
  } catch (error) {
    console.error("Error writing metadata:", error)
  }
}

// Upload endpoint
app.post("/upload", upload.single("image"), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file uploaded",
      })
    }

    // Read existing metadata
    const metadata = readMetadata()

    // Create new image metadata
    const imageData = {
      id: Date.now().toString(),
      name: req.file.originalname,
      filename: req.file.filename,
      size: req.file.size,
      url: `/uploads/${req.file.filename}`,
      uploadedAt: new Date().toISOString(),
    }

    // Add to metadata array
    metadata.push(imageData)

    // Save metadata
    writeMetadata(metadata)

    res.json({
      success: true,
      url: imageData.url,
    })
  } catch (error) {
    console.error("Upload error:", error)
    res.status(500).json({
      success: false,
      message: "Upload failed",
    })
  }
})

// Get all images endpoint
app.get("/images", (req, res) => {
  try {
    const metadata = readMetadata()
    res.json(metadata)
  } catch (error) {
    console.error("Error fetching images:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch images",
    })
  }
})

// Delete image endpoint
app.delete("/images/:id", (req, res) => {
  try {
    const imageId = req.params.id
    const metadata = readMetadata()

    // Find the image to delete
    const imageIndex = metadata.findIndex((img) => img.id === imageId)

    if (imageIndex === -1) {
      return res.status(404).json({
        success: false,
        message: "Image not found",
      })
    }

    const imageToDelete = metadata[imageIndex]

    // Delete the physical file
    const filePath = path.join(__dirname, "uploads", imageToDelete.filename)
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath)
    }

    // Remove from metadata
    metadata.splice(imageIndex, 1)

    // Save updated metadata
    writeMetadata(metadata)

    res.json({
      success: true,
      message: "Image deleted successfully",
    })
  } catch (error) {
    console.error("Delete error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to delete image",
    })
  }
})

// Handle multer errors
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        message: "File too large. Maximum size is 5MB.",
      })
    }
  }

  if (error.message === "Only image files (JPEG, PNG, GIF) are allowed") {
    return res.status(400).json({
      success: false,
      message: error.message,
    })
  }

  res.status(500).json({
    success: false,
    message: "Server error",
  })
})

// Basic route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"))
})

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})
