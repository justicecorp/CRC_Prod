describe('Validate site counter is present', () => {
  it('visits, gets, asserts', () => {
    cy.visit(Cypress.env('url'))

    cy.contains('Unique Visitor Count')

    cy.get('#CounterVal')
      .should('be.visible')
      .should('not.be.empty')
  })
})