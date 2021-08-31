describe('Login', () => {
    
    it('Invalid user login attempt', () => {
        cy.visit('/dataset')
        cy.get('a[href="/user/login"]').click()
        cy.login('not-user', 'not-password', true)
        cy.get('.flash-messages .alert').should('contain', 'Login failed. Bad username or password.')
        // Validate cookie is not set
        cy.getCookie('auth_tkt').should('not.exist');
    });

    it('Valid login attempt', () => {
        cy.visit('/dataset')
        cy.get('a[href="/user/login"]').click()
        cy.login()
        cy.get('.nav-tabs>li>a').should('contain', 'My Organizations')
        // Validate cookie is set, in development secure is set to false
        cy.getCookie('auth_tkt').should('have.property', 'secure', 'false');
    })

})
