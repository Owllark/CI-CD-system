describe('template spec', () => {
  it('home page should contain Welcome h1', () => {
    cy.visit('http://webapp-service.staging.svc.cluster.local')
    cy.get('h1').should('contain', 'Welcome')
  })
})
