class ImageUploader {
  constructor() {
    this.fileInput = document.getElementById("fileInput")
    this.uploadBtn = document.getElementById("uploadBtn")
    this.dropZone = document.getElementById("dropZone")
    this.uploadStatus = document.getElementById("uploadStatus")
    this.progressContainer = document.getElementById("progressContainer")
    this.progressBar = document.getElementById("progressBar")
    this.progressText = document.getElementById("progressText")
    this.imageGallery = document.getElementById("imageGallery")
    this.emptyState = document.getElementById("emptyState")

    this.selectedFiles = []

    this.initEventListeners()
    this.loadImages()
  }

  initEventListeners() {
    // File input change
    this.fileInput.addEventListener("change", (e) => {
      this.handleFileSelect(e.target.files)
    })

    // Upload button click
    this.uploadBtn.addEventListener("click", () => {
      this.uploadFiles()
    })

    // Drag and drop events
    this.dropZone.addEventListener("dragover", (e) => {
      e.preventDefault()
      this.dropZone.classList.add("drag-over")
    })

    this.dropZone.addEventListener("dragleave", (e) => {
      e.preventDefault()
      this.dropZone.classList.remove("drag-over")
    })

    this.dropZone.addEventListener("drop", (e) => {
      e.preventDefault()
      this.dropZone.classList.remove("drag-over")
      this.handleFileSelect(e.dataTransfer.files)
    })
  }

  handleFileSelect(files) {
    this.selectedFiles = Array.from(files)
    this.uploadBtn.disabled = this.selectedFiles.length === 0

    if (this.selectedFiles.length > 0) {
      this.showStatus(`${this.selectedFiles.length} file(s) selected`, "success")
    }
  }

  async uploadFiles() {
    if (this.selectedFiles.length === 0) return

    this.uploadBtn.disabled = true
    this.showProgress(true)

    let uploadedCount = 0
    const totalFiles = this.selectedFiles.length

    for (let i = 0; i < this.selectedFiles.length; i++) {
      const file = this.selectedFiles[i]

      try {
        await this.uploadSingleFile(file)
        uploadedCount++

        const progress = Math.round((uploadedCount / totalFiles) * 100)
        this.updateProgress(progress)
      } catch (error) {
        console.error("Upload failed for file:", file.name, error)
        this.showStatus(`Failed to upload ${file.name}: ${error.message}`, "error")
      }
    }

    if (uploadedCount === totalFiles) {
      this.showStatus(`Successfully uploaded ${uploadedCount} file(s)`, "success")
    } else {
      this.showStatus(`Uploaded ${uploadedCount} of ${totalFiles} files`, "error")
    }

    // Reset form
    this.fileInput.value = ""
    this.selectedFiles = []
    this.uploadBtn.disabled = true

    // Hide progress after delay
    setTimeout(() => {
      this.showProgress(false)
    }, 2000)

    // Reload gallery
    this.loadImages()
  }

  async uploadSingleFile(file) {
    const formData = new FormData()
    formData.append("image", file)

    const response = await fetch("/upload", {
      method: "POST",
      body: formData,
    })

    const result = await response.json()

    if (!result.success) {
      throw new Error(result.message || "Upload failed")
    }

    return result
  }

  async loadImages() {
    try {
      const response = await fetch("/images")
      const images = await response.json()

      this.renderGallery(images)
    } catch (error) {
      console.error("Failed to load images:", error)
      this.showStatus("Failed to load images", "error")
    }
  }

  renderGallery(images) {
    if (images.length === 0) {
      this.emptyState.style.display = "block"
      this.imageGallery.innerHTML = ""
      this.imageGallery.appendChild(this.emptyState)
      return
    }

    this.emptyState.style.display = "none"

    this.imageGallery.innerHTML = images
      .map(
        (image) => `
            <div class="image-card">
                <img src="${image.url}" alt="${image.name}" loading="lazy">
                <div class="image-info">
                    <div class="image-name">${image.name}</div>
                    <div class="image-size">${this.formatFileSize(image.size)}</div>
                    <button class="delete-btn" onclick="imageUploader.deleteImage('${image.id}')">
                        Delete
                    </button>
                </div>
            </div>
        `,
      )
      .join("")
  }

  async deleteImage(imageId) {
    if (!confirm("Are you sure you want to delete this image?")) {
      return
    }

    try {
      const response = await fetch(`/images/${imageId}`, {
        method: "DELETE",
      })

      const result = await response.json()

      if (result.success) {
        this.showStatus("Image deleted successfully", "success")
        this.loadImages()
      } else {
        this.showStatus(result.message || "Failed to delete image", "error")
      }
    } catch (error) {
      console.error("Delete failed:", error)
      this.showStatus("Failed to delete image", "error")
    }
  }

  showStatus(message, type) {
    this.uploadStatus.textContent = message
    this.uploadStatus.className = `upload-status ${type}`

    // Clear status after 5 seconds
    setTimeout(() => {
      this.uploadStatus.textContent = ""
      this.uploadStatus.className = "upload-status"
    }, 5000)
  }

  showProgress(show) {
    this.progressContainer.style.display = show ? "flex" : "none"
    if (!show) {
      this.updateProgress(0)
    }
  }

  updateProgress(percent) {
    this.progressBar.style.width = `${percent}%`
    this.progressText.textContent = `${percent}%`
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"

    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))

    return Number.parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }
}

// Initialize the uploader when DOM is loaded
document.addEventListener("DOMContentLoaded", () => {
  window.imageUploader = new ImageUploader()
})
