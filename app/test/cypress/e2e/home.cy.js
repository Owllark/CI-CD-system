describe('template spec', () => {
  it('home page should contain Welcome h1', () => {
    cy.visit('https://localhost:44361/Home')
    cy.get('h1').should('contain', 'Welcome')
  })
})