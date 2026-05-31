import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { Provider } from 'react-redux'
import { BrowserRouter } from 'react-router-dom'
import { store } from './app/store'
import App from './App'
import './index.css'

const shouldUseMocks = import.meta.env.VITE_USE_MOCKS === 'true'

async function enableMocking() {
  if (!shouldUseMocks) {
    return
  }

  const { worker } = await import('./mocks/browser')
  await worker.start({
    onUnhandledRequest: 'bypass',
    serviceWorker: {
      url: '/mockServiceWorker.js',
    },
  })
}

enableMocking().then(() => {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <Provider store={store}>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </Provider>
    </StrictMode>,
  )
})
