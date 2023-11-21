describe('My First Test', () => {
  it('Gets, types and asserts', () => {
    cy.visit('https://resumegha.prod.justicecorp.org/')

    cy.contains('Unique Visitor Count')

    // Should be on a new URL which
    // includes '/commands/actions'
    //cy.url().should('include', '/commands/actions')

    // Get an input, type into it
    //cy.get('#CounterVal').should('match', /^[0-9]*$/)
    cy.get('#CounterVal')
      .should('be.visible')
      .should('not.be.empty')
      //.should('eq', '5')


    // Found here: https://github.com/cypress-io/cypress/discussions/22293
    // Doesn't work, but good start.
    /*cy.get('#CounterVal') 
      .then((text) => {
        const matcher = /\((?<number>\d+)\)/;
        return text.match(matcher)?.groups?.number;
      })
      .then(parseInt)
      .should("be.greaterThan", 0);

    //  Verify that the value has been updated
    //cy.get('.action-email').should('have.value', 'fake@email.com')
    */
  })
})