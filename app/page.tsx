"use client"

import type React from "react"

import { useEffect, useState } from "react"

interface ImageData {
  id: string
  name: string
  filename: string
  size: number
  url: string
  uploadedAt: string
}

export default function ImageUploader() {
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [images, setImages] = useState<ImageData[]>([])
  const [uploadStatus, setUploadStatus] = useState<{
    message: string
    type: "success" | "error" | "loading" | ""
  }>({ message: "", type: "" })
  const [isUploading, setIsUploading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [showProgress, setShowProgress] = useState(false)

  useEffect(() => {
    loadImages()
  }, [])

  const handleFileSelect = (files: FileList | null) => {
    if (files) {
      const fileArray = Array.from(files)
      setSelectedFiles(fileArray)
      if (fileArray.length > 0) {
        showStatus(`${fileArray.length} file(s) selected`, "success")
      }
    }
  }

  const uploadFiles = async () => {
    if (selectedFiles.length === 0) return

    setIsUploading(true)
    setShowProgress(true)
    setUploadProgress(0)

    let uploadedCount = 0
    const totalFiles = selectedFiles.length

    for (let i = 0; i < selectedFiles.length; i++) {
      const file = selectedFiles[i]

      try {
        await uploadSingleFile(file)
        uploadedCount++
        const progress = Math.round((uploadedCount / totalFiles) * 100)
        setUploadProgress(progress)
      } catch (error: any) {
        console.error("Upload failed for file:", file.name, error)
        showStatus(`Failed to upload ${file.name}: ${error.message}`, "error")
      }
    }

    if (uploadedCount === totalFiles) {
      showStatus(`Successfully uploaded ${uploadedCount} file(s)`, "success")
    } else {
      showStatus(`Uploaded ${uploadedCount} of ${totalFiles} files`, "error")
    }

    // Reset form
    setSelectedFiles([])
    setIsUploading(false)

    // Hide progress after delay
    setTimeout(() => {
      setShowProgress(false)
      setUploadProgress(0)
    }, 2000)

    // Reload gallery
    loadImages()
  }

  const uploadSingleFile = async (file: File) => {
    const formData = new FormData()
    formData.append("image", file)

    const response = await fetch("/api/upload", {
      method: "POST",
      body: formData,
    })

    const result = await response.json()

    if (!result.success) {
      throw new Error(result.message || "Upload failed")
    }

    return result
  }

  const loadImages = async () => {
    try {
      const response = await fetch("/api/images")
      const imageData = await response.json()
      setImages(imageData)
    } catch (error) {
      console.error("Failed to load images:", error)
      showStatus("Failed to load images", "error")
    }
  }

  const deleteImage = async (imageId: string) => {
    if (!confirm("Are you sure you want to delete this image?")) {
      return
    }

    try {
      // URL encode the imageId to handle special characters like "/"
      const encodedId = encodeURIComponent(imageId)
      const response = await fetch(`/api/images/${encodedId}`, {
        method: "DELETE",
      })

      const result = await response.json()

      if (result.success) {
        showStatus("Image deleted successfully", "success")
        loadImages()
      } else {
        showStatus(result.message || "Failed to delete image", "error")
      }
    } catch (error) {
      console.error("Delete failed:", error)
      showStatus("Failed to delete image", "error")
    }
  }

  const showStatus = (message: string, type: "success" | "error" | "loading") => {
    setUploadStatus({ message, type })
    setTimeout(() => {
      setUploadStatus({ message: "", type: "" })
    }, 5000)
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Number.parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    e.currentTarget.classList.add("drag-over")
  }

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault()
    e.currentTarget.classList.remove("drag-over")
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    e.currentTarget.classList.remove("drag-over")
    handleFileSelect(e.dataTransfer.files)
  }

  return (
    <div className="container">
      <header className="header">
        <h1>Image Uploader</h1>
        <p>Upload, manage, and organize your images with ease</p>
      </header>

      <main className="main">
        {/* Upload Section */}
        <section className="upload-section">
          <h2>STEP 1: UPLOAD IMAGE</h2>
          <p>Upload your images (JPEG, PNG, GIF). Maximum file size is 5MB per image.</p>

          <div className="upload-area">
            <div className="file-input-wrapper">
              <input
                type="file"
                id="fileInput"
                accept="image/*"
                multiple
                onChange={(e) => handleFileSelect(e.target.files)}
                className="file-input"
              />
              <label htmlFor="fileInput" className="file-input-label">
                Choose Images
              </label>
            </div>

            <div className="upload-button-wrapper">
              <button onClick={uploadFiles} disabled={selectedFiles.length === 0 || isUploading} className="upload-btn">
                {isUploading ? "Uploading..." : "Upload"}
              </button>
              {uploadStatus.message && (
                <div className={`upload-status ${uploadStatus.type}`}>{uploadStatus.message}</div>
              )}
            </div>
          </div>

          <div className="drop-zone" onDragOver={handleDragOver} onDragLeave={handleDragLeave} onDrop={handleDrop}>
            <p>Drag & Drop images here</p>
          </div>

          {showProgress && (
            <div className="progress-container">
              <div className="progress-bar">
                <div className="progress-fill" style={{ width: `${uploadProgress}%` }}></div>
              </div>
              <span className="progress-text">{uploadProgress}%</span>
            </div>
          )}
        </section>

        {/* Gallery Section */}
        <section className="gallery-section">
          <h2>STEP 2: MANAGE IMAGES</h2>
          <p>View and manage your uploaded images</p>

          <div className="image-gallery">
            {images.length === 0 ? (
              <div className="empty-state">
                <p>No images uploaded yet. Upload some images to get started!</p>
              </div>
            ) : (
              images.map((image) => (
                <div key={image.id} className="image-card">
                  <img src={image.url || "/placeholder.svg"} alt={image.name} loading="lazy" />
                  <div className="image-info">
                    <div className="image-name">{image.name}</div>
                    <div className="image-size">{formatFileSize(image.size)}</div>
                    <button onClick={() => deleteImage(image.filename)} className="delete-btn">
                      Delete
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </section>
      </main>
    </div>
  )
}
