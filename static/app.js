const fileInput = document.getElementById('file')
const runBtn = document.getElementById('run')
const status = document.getElementById('status')
const canvas = document.getElementById('canvas')
const ctx = canvas.getContext('2d')

function setStatus(t){ status.textContent = t }

runBtn.addEventListener('click', async () => {
  if (!fileInput.files || fileInput.files.length === 0) {
    setStatus('Select a file first')
    return
  }
  setStatus('Uploading...')
  const file = fileInput.files[0]
  const form = new FormData()
  form.append('image', file)

  try {
    const res = await fetch('/process_image', { method: 'POST', body: form })
    if (!res.ok) {
      setStatus('Server error: ' + res.status)
      return
    }
    const data = await res.json()
    setStatus('Processing complete')

    // Load the processed image into the canvas
    const img = new Image()
    img.onload = () => {
      canvas.width = img.naturalWidth
      canvas.height = img.naturalHeight
      ctx.drawImage(img, 0, 0)

      // draw boxes if present
      if (data.boxes && data.boxes.length) {
        ctx.strokeStyle = 'red'
        ctx.lineWidth = Math.max(2, Math.round(canvas.width/400))
        ctx.font = `${Math.max(12, Math.round(canvas.width/60))}px Arial`
        data.boxes.forEach(b => {
          const [x1,y1,x2,y2] = b.bbox
          ctx.strokeRect(x1, y1, x2-x1, y2-y1)
          ctx.fillStyle = 'rgba(255,255,255,0.8)'
          const text = b.price
          const textW = ctx.measureText(text).width
          const pad = 6
          ctx.fillRect(x1, y1 - 30, textW + pad*2, 26)
          ctx.fillStyle = 'black'
          ctx.fillText(text, x1 + pad, y1 - 8)
        })
      }
    }
    img.src = data.image_url

  } catch (err) {
    console.error(err)
    setStatus('Error: ' + err.message)
  }
})
