import React, { useState } from 'react';
import { web3, hotelBooking } from '../utils/web3';

const CancelBooking = () => {
    const [roomId, setRoomId] = useState('');
    const [account, setAccount] = useState('');
    const [refundAmount, setRefundAmount] = useState(0);

    const handleCancel = async () => {
        const accounts = await web3.eth.getAccounts();
        setAccount(accounts[0]);

        const roomBooking = await hotelBooking.methods.roomBookings(roomId).call();
        const bookingTime = roomBooking.bookingTime;
        const price = await hotelBooking.methods.rooms(roomId).call().price;

        const elapsed = Math.floor((Date.now() / 1000) - bookingTime);
        let refundPercentage = 0;

        if (elapsed < 60) {
            refundPercentage = 100;
        } else if (elapsed < 120) {
            refundPercentage = 90;
        } else if (elapsed < 180) {
            refundPercentage = 80;
        } else if (elapsed < 240) {
            refundPercentage = 70;
        } else if (elapsed < 300) {
            refundPercentage = 60;
        }

        const refund = (price * refundPercentage) / 100;
        setRefundAmount(refund);

        await hotelBooking.methods.cancelBooking(roomId)
            .send({ from: account });

        alert(`Booking cancelled successfully! Refund amount: ${web3.utils.fromWei(refund.toString(), 'ether')} ETH`);
    };

    return (
        <div>
            <h2>Cancel Booking</h2>
            <input type="number" placeholder="Room ID" value={roomId} onChange={e => setRoomId(e.target.value)} />
            <button onClick={handleCancel}>Cancel</button>
            {refundAmount > 0 && (
                <p>Refund Amount: {web3.utils.fromWei(refundAmount.toString(), 'ether')} ETH</p>
            )}
        </div>
    );
};

export default CancelBooking;
