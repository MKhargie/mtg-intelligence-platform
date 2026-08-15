import { expect, test } from 'vitest'
import { render, screen } from '@testing-library/react'

import App from './App'

test('renders the application heading', () => {
  render(<App />)

  const heading = screen.getByRole('heading', {
    level: 1,
    name: 'MTG Intelligence Platform',
  })

  expect(heading).toBeInTheDocument()
})
