import "./style.css"
import Canvas from "./canvas"

class PNGSequencePlayer {
  images: HTMLImageElement[] = []
  currentFrame: number = 0
  fps: number = 30
  lastFrameTime: number = 0
  imgElement: HTMLImageElement | null = null
  isLoaded: boolean = false

  constructor(imgElementId: string) {
    this.imgElement = document.getElementById(imgElementId) as HTMLImageElement
  }

  async loadSequence(basePath: string, startFrame: number, endFrame: number, padLength: number = 4) {
    const promises: Promise<HTMLImageElement>[] = []

    for (let i = startFrame; i <= endFrame; i++) {
      const frameNum = String(i).padStart(padLength, '0')
      const url = `${basePath}${frameNum}.png`

      promises.push(
        new Promise((resolve, reject) => {
          const img = new Image()
          img.onload = () => resolve(img)
          img.onerror = reject
          img.src = url
        })
      )
    }

    this.images = await Promise.all(promises)
    this.isLoaded = true
    console.log(`Loaded ${this.images.length} frames`)

    // 첫 프레임 설정
    if (this.images.length > 0 && this.imgElement) {
      this.imgElement.src = this.images[0].src
    }
  }

  update(timestamp: number) {
    if (!this.isLoaded || this.images.length === 0 || !this.imgElement) return

    const frameDuration = 1000 / this.fps

    if (timestamp - this.lastFrameTime >= frameDuration) {
      this.currentFrame = (this.currentFrame + 1) % this.images.length
      this.imgElement.src = this.images[this.currentFrame].src
      this.lastFrameTime = timestamp
    }
  }
}

// 클릭으로 재생/역재생하는 플레이어
class ClickSequencePlayer {
  images: HTMLImageElement[] = []
  currentFrame: number = 0
  fps: number = 30
  lastFrameTime: number = 0
  imgElement: HTMLImageElement | null = null
  isLoaded: boolean = false
  
  // 재생 상태: 'idle' | 'playing' | 'done' | 'reversing'
  state: 'idle' | 'playing' | 'done' | 'reversing' = 'idle'

  constructor(imgElementId: string) {
    this.imgElement = document.getElementById(imgElementId) as HTMLImageElement
    
    // 클릭 이벤트 바인딩
    if (this.imgElement) {
      this.imgElement.style.cursor = 'pointer'
      this.imgElement.addEventListener('click', () => this.onClick())
    }
  }

  async loadSequence(basePath: string, startFrame: number, endFrame: number, padLength: number = 4) {
    const promises: Promise<HTMLImageElement>[] = []

    for (let i = startFrame; i <= endFrame; i++) {
      const frameNum = String(i).padStart(padLength, '0')
      const url = `${basePath}${frameNum}.png`

      promises.push(
        new Promise((resolve, reject) => {
          const img = new Image()
          img.onload = () => resolve(img)
          img.onerror = reject
          img.src = url
        })
      )
    }

    this.images = await Promise.all(promises)
    this.isLoaded = true
    console.log(`Loaded ${this.images.length} frames (click to play)`)

    // 첫 프레임 설정
    if (this.images.length > 0 && this.imgElement) {
      this.imgElement.src = this.images[0].src
    }
  }

  onClick() {
    if (!this.isLoaded) return

    if (this.state === 'idle') {
      // 정재생 시작
      this.state = 'playing'
      this.currentFrame = 0
    } else if (this.state === 'done') {
      // 역재생 시작
      this.state = 'reversing'
    }
  }

  update(timestamp: number) {
    if (!this.isLoaded || this.images.length === 0 || !this.imgElement) return
    if (this.state === 'idle' || this.state === 'done') return

    const frameDuration = 1000 / this.fps

    if (timestamp - this.lastFrameTime >= frameDuration) {
      if (this.state === 'playing') {
        // 정재생
        this.currentFrame++
        if (this.currentFrame >= this.images.length) {
          this.currentFrame = this.images.length - 1
          this.state = 'done'
        }
      } else if (this.state === 'reversing') {
        // 역재생
        this.currentFrame--
        if (this.currentFrame <= 0) {
          this.currentFrame = 0
          this.state = 'idle'
        }
      }

      this.imgElement.src = this.images[this.currentFrame].src
      this.lastFrameTime = timestamp
    }
  }
}

class App {
  canvas: Canvas
  textSequencePlayer: PNGSequencePlayer
  letterSequencePlayer: ClickSequencePlayer

  constructor() {
    this.canvas = new Canvas()
    this.textSequencePlayer = new PNGSequencePlayer('text-sequence')
    this.letterSequencePlayer = new ClickSequencePlayer('letter-sequence')
    this.initSequence()
    this.render()
  }

  async initSequence() {
    const base = import.meta.env.BASE_URL
    // text 시퀀스 로드 (0021.png ~ 0120.png) - 무한 루프
    await this.textSequencePlayer.loadSequence(`${base}covers/5/text/`, 21, 120)
    // letter 시퀀스 로드 (0100.png ~ 0200.png) - 클릭 재생/역재생
    await this.letterSequencePlayer.loadSequence(`${base}covers/5/letter/`, 0, 200)
  }

  render(timestamp: number = 0) {
    this.canvas.render()
    this.textSequencePlayer.update(timestamp)
    this.letterSequencePlayer.update(timestamp)
    requestAnimationFrame(this.render.bind(this))
  }
}

export default new App()
