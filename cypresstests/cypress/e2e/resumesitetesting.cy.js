describe('Validate site counter is present', () => {
  it('visits, gets, asserts', () => {
    // This will visit the index page which should be the home page
    cy.visit(Cypress.env('ghaurl'))

    cy.contains('Unique Visitor Count')

    cy.get('#CounterVal')
      .should('be.visible')
      .should('not.be.empty')
  })
})