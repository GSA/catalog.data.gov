describe('Login', () => {
    it('Invalid user login attempt', () => {
        cy.visit('/dataset');
        cy.get('a[href="/user/login"]').click();
        cy.login('not-user', 'not-password');
        cy.get('.flash-messages .alert').should('contain', 'Login failed. Bad username or password.');
    });

    it('Valid login attempt', () => {
        cy.visit('/dataset');
        cy.get('a[href="/user/login"]').click();
        cy.login();
        cy.get('.nav-tabs>li>a').should('contain', 'My Organizations');
    });
});
