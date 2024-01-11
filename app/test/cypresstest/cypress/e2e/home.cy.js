describe('template spec', () => {
  it('home page should contain Welcome h1', () => {
    cy.visit('http://localhost:8080')
    cy.get('h1').should('contain', 'Welcome')
  })
})
