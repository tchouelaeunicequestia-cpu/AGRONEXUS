package com.agronexus.api.service;

import com.agronexus.api.entity.Order;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class OrderEmailService {

    private final JavaMailSender mailSender;
    private final String fromAddress;

    public OrderEmailService(
            JavaMailSender mailSender,
            @Value("${agronexus.notifications.from-address}") String fromAddress) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
    }

    public void sendOrderCreatedEmail(Order order) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(order.getBuyer().getEmail());
        message.setSubject("AgroNexus order " + order.getOrderCode());
        message.setText("""
                Hello %s,

                Your AgroNexus order has been created.
                Delivery orders remain pending until a transporter submits a quote and you approve it.

                Order code: %s
                Produce: %s
                Quantity: %s
                Escrow amount: %s
                Status: %s

                Keep this order code for delivery confirmation and support.
                """.formatted(
                order.getBuyer().getFullName(),
                order.getOrderCode(),
                order.getProduct().getTitle(),
                order.getQuantity(),
                order.getTotalEscrowAmount().signum() == 0
                        ? "Pending transporter quote and buyer approval"
                        : order.getTotalEscrowAmount().toPlainString() + " XAF",
                order.getEscrowStatus()));
        mailSender.send(message);
    }
}
